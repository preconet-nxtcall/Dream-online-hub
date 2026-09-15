import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../models/chat/chat_message_model.dart';
import '../../../../models/dto/chat/send_message_request_dto.dart';
import '../../../../models/user/recharge_record_model.dart';
import '../../../../network/api_client.dart';
import '../../../../network/chat_api_client.dart';
import '../../../../providers/chat_provider.dart';
import '../../../../socket/socket_events.dart';
import '../../../../socket/socket_service.dart';
import '../../../../storage/local_storage_repository.dart';
import '../../../../storage/secure_storage_service.dart';

class RechargeNowWidget extends StatefulWidget {
  final Function(RechargeRecordModel)? onRechargeSubmitted;
  final int? bookId;
  final int? agencyId;

  const RechargeNowWidget({
    super.key,
    this.onRechargeSubmitted,
    this.bookId,
    this.agencyId,
  });

  @override
  State<RechargeNowWidget> createState() => _RechargeNowWidgetState();
}

class _RechargeNowWidgetState extends State<RechargeNowWidget> {
  String? _selectedBook;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _txnIdController = TextEditingController();
  File? _selectedScreenshot;
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;

  // QR Code Backend Integration state
  bool _isLoadingQr = false;
  bool? _qrAvailable;
  String? _qrImageUrl;
  String? _qrMessage;
  int? _qrId;
  int? _rangeId;
  int? _empId;
  Timer? _debounceTimer;

  Map<String, int> _dynamicBookIds = {};
  List<String> _books = [];

  Future<dynamic> _resolveUserId() async {
    try {
      final currentUser = LocalStorageRepositoryImpl().getUser();
      if (currentUser?.id != null && currentUser!.id.isNotEmpty) {
        final raw = currentUser.id.trim();
        final digitsOnly = raw.replaceAll(RegExp(r'\D'), '');
        return digitsOnly.isNotEmpty ? (int.tryParse(digitsOnly) ?? raw) : raw;
      }
    } catch (_) {}
    try {
      final storedUserId = await SecureStorageService().read(StorageKeys.userId);
      if (storedUserId != null && storedUserId.isNotEmpty) {
        final raw = storedUserId.trim();
        final digitsOnly = raw.replaceAll(RegExp(r'\D'), '');
        return digitsOnly.isNotEmpty ? (int.tryParse(digitsOnly) ?? raw) : raw;
      }
    } catch (_) {}
    return null;
  }

  Future<dynamic> _resolveAgencyId() async {
    if (widget.agencyId != null && widget.agencyId! > 0) {
      return widget.agencyId;
    }
    try {
      final currentUser = LocalStorageRepositoryImpl().getUser();
      final userAgency = currentUser?.agencyId;
      if (userAgency != null &&
          userAgency.isNotEmpty &&
          userAgency != 'null' &&
          userAgency != '0') {
        final digitsOnly = userAgency.replaceAll(RegExp(r'\D'), '');
        if (digitsOnly.isNotEmpty) {
          return int.tryParse(digitsOnly) ?? userAgency;
        }
        return userAgency;
      }
    } catch (_) {}
    try {
      final storedAgentId = await SecureStorageService().read(StorageKeys.chatAgentId);
      if (storedAgentId != null &&
          storedAgentId.isNotEmpty &&
          storedAgentId != 'null' &&
          storedAgentId != '0') {
        final digitsOnly = storedAgentId.replaceAll(RegExp(r'\D'), '');
        if (digitsOnly.isNotEmpty) {
          return int.tryParse(digitsOnly) ?? storedAgentId;
        }
        return storedAgentId;
      }
    } catch (_) {}
    return null;
  }

  Future<void> _fetchBooks() async {
    try {
      final apiClient = ApiClient();
      final userId = await _resolveUserId();
      final response = await apiClient.post(
        ApiEndpoints.getQrCode,
        options: Options(validateStatus: (status) => status != null && status < 500),
        data: {
          'action': 'all_books',
          'user_id': userId,
        },
      );

      if (!mounted) return;
      final data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true) {
        final List<String> fetchedBooks = [];
        final Map<String, int> bookMap = {};
        final List rawList = [];

        // 1. Prioritize subscribed_books (only show subscribed / successfully ordered books)
        if (data['subscribed_books'] is List && (data['subscribed_books'] as List).isNotEmpty) {
          rawList.addAll(data['subscribed_books'] as List);
        } else if (data['user_books'] is List && (data['user_books'] as List).isNotEmpty) {
          rawList.addAll(data['user_books'] as List);
        } else if (data['my_books'] is List && (data['my_books'] as List).isNotEmpty) {
          rawList.addAll(data['my_books'] as List);
        }

        // 2. If subscribed_books key is not directly present, check all_books / data and filter only subscribed items
        if (rawList.isEmpty) {
          final List sourceList = [];
          if (data['all_books'] is List) {
            sourceList.addAll(data['all_books'] as List);
          } else if (data['books'] is List) {
            sourceList.addAll(data['books'] as List);
          } else if (data['data'] is List) {
            sourceList.addAll(data['data'] as List);
          }

          for (final item in sourceList) {
            if (item is Map) {
              final isSubscribed = item['is_subscribed'] == true ||
                  item['is_subscribed'] == 1 ||
                  item['already_subscribed'] == true ||
                  item['already_subscribed'] == 1 ||
                  item['subscribed'] == true ||
                  item['subscribed'] == 1 ||
                  item['status']?.toString().toUpperCase() == 'SUBSCRIBED' ||
                  item['status']?.toString().toUpperCase() == 'SUCCESS' ||
                  item['status']?.toString().toUpperCase() == 'ACTIVE';
              if (isSubscribed) {
                rawList.add(item);
              }
            }
          }
        }

        for (final item in rawList) {
          if (item is Map) {
            final username = (item['username'] ??
                    item['user_name'] ??
                    item['client_username'] ??
                    item['user'] ??
                    item['account_username'] ??
                    '')
                .toString()
                .trim();

            final password = (item['password'] ??
                    item['pass'] ??
                    item['client_password'] ??
                    item['account_password'] ??
                    '')
                .toString()
                .trim();

            final bool hasCredentials = (username.isNotEmpty && username != 'null' && username != '0') ||
                (password.isNotEmpty && password != 'null' && password != '0') ||
                item['has_credentials'] == true ||
                item['has_credentials'] == 1 ||
                item['has_id'] == true ||
                item['has_id'] == 1;

            final isSubscribed = item['is_subscribed'] == true ||
                item['is_subscribed'] == 1 ||
                item['already_subscribed'] == true ||
                item['already_subscribed'] == 1 ||
                item['subscribed'] == true ||
                item['subscribed'] == 1 ||
                item['status']?.toString().toUpperCase() == 'SUBSCRIBED' ||
                item['status']?.toString().toUpperCase() == 'SUCCESS' ||
                item['status']?.toString().toUpperCase() == 'ACTIVE';

            // Only include books that have assigned username & password credentials
            if (hasCredentials || (isSubscribed && (username.isNotEmpty || password.isNotEmpty))) {
              final String name = item['book_name']?.toString() ??
                  item['bookName']?.toString() ??
                  item['name']?.toString() ??
                  item['title']?.toString() ??
                  '';
              final int bId = int.tryParse(item['id']?.toString() ?? item['book_id']?.toString() ?? '0') ?? 0;

              if (name.isNotEmpty && !fetchedBooks.contains(name)) {
                fetchedBooks.add(name);
                if (bId > 0) {
                  bookMap[name] = bId;
                }
              }
            }
          }
        }

        setState(() {
          _books = fetchedBooks.toSet().toList();
          _dynamicBookIds = bookMap;
          if (_selectedBook != null && !_books.contains(_selectedBook)) {
            _selectedBook = null;
          }
          if (_selectedBook == null && _books.isNotEmpty) {
            _selectedBook = _books.first;
          }
        });
      }
    } catch (_) {
      // Keep state on network error
    }
  }

  int? _getBookId(String? bookName) {
    if (bookName != null && bookName.isNotEmpty) {
      final normalized = bookName.trim().toLowerCase();
      for (final entry in _dynamicBookIds.entries) {
        if (entry.key.trim().toLowerCase() == normalized) {
          return entry.value;
        }
      }
    }
    return widget.bookId;
  }

  @override
  void initState() {
    super.initState();
    _selectedBook = null;
    _amountController.addListener(_onAmountChanged);
    _fetchBooks();
  }

  void _onAmountChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      if (mounted) _fetchQrCode();
    });
  }

  Future<void> _fetchQrCode() async {
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      if (mounted) {
        setState(() {
          _isLoadingQr = false;
          _qrAvailable = null;
          _qrImageUrl = null;
          _qrMessage = null;
          _qrId = null;
          _rangeId = null;
          _empId = null;
        });
      }
      return;
    }

    setState(() {
      _isLoadingQr = true;
      _qrMessage = null;
    });

    try {
      final apiClient = ApiClient();
      final targetBookId = _getBookId(_selectedBook);
      final resolvedAgencyId = await _resolveAgencyId();

      final options = Options(validateStatus: (status) => status != null && status < 500);
      final payload = {
        'action': 'get_qr_code',
        'book_id': targetBookId,
        'agency_id': resolvedAgencyId,
        'amount': amount,
      };

      var response = await apiClient.post(
        ApiEndpoints.getQrCode,
        options: options,
        data: payload,
      );

      var data = response.data;
      if (response.statusCode == 400 || data is! Map<String, dynamic> || data['success'] != true) {
        try {
          final formResp = await apiClient.post(
            ApiEndpoints.getQrCode,
            options: Options(
              contentType: Headers.formUrlEncodedContentType,
              validateStatus: (status) => status != null && status < 500,
            ),
            data: {
              'action': 'get_qr_code',
              'book_id': (targetBookId ?? '').toString(),
              'agency_id': (resolvedAgencyId ?? '').toString(),
              'amount': amount.toString(),
            },
          );
          if (formResp.data is Map<String, dynamic> && formResp.data['success'] == true) {
            data = formResp.data;
          }
        } catch (_) {}
      }

      if (!mounted) return;

      if (data is Map<String, dynamic> && data['success'] == true) {
        if (data['qr_available'] == true) {
          String? rawQrUrl = data['qr_image_url']?.toString() ??
              data['qr_image']?.toString() ??
              data['image_url']?.toString() ??
              data['image']?.toString();

          if (rawQrUrl != null && rawQrUrl.isNotEmpty && rawQrUrl != 'null') {
            if (!rawQrUrl.startsWith('http://') && !rawQrUrl.startsWith('https://')) {
              final cleanPath = rawQrUrl.startsWith('/') ? rawQrUrl.substring(1) : rawQrUrl;
              if (cleanPath.startsWith('uploads/')) {
                rawQrUrl = '${ApiEndpoints.baseUrl}$cleanPath';
              } else {
                rawQrUrl = '${ApiEndpoints.baseUrl}uploads/photos/$cleanPath';
              }
            }
          }

          setState(() {
            _isLoadingQr = false;
            _qrAvailable = true;
            _qrImageUrl = rawQrUrl;
            _qrId = data['qr_id'] != null ? int.tryParse(data['qr_id'].toString()) : null;
            _rangeId = data['range_id'] != null ? int.tryParse(data['range_id'].toString()) : null;
            _empId = data['emp_id'] != null ? int.tryParse(data['emp_id'].toString()) : null;
            _qrMessage = null;
          });
        } else {
          setState(() {
            _isLoadingQr = false;
            _qrAvailable = false;
            _qrMessage = data['message']?.toString() ?? 'Only Cash Transaction Available.';
            _qrImageUrl = null;
            _qrId = data['qr_id'] != null ? int.tryParse(data['qr_id'].toString()) : null;
            _rangeId = data['range_id'] != null ? int.tryParse(data['range_id'].toString()) : null;
            _empId = null;
          });
        }
      } else {
        _applyDatabaseQrFallback(amount);
      }
    } catch (e) {
      if (!mounted) return;
      _applyDatabaseQrFallback(amount);
    }
  }

  void _applyDatabaseQrFallback(double amount) {
    if (!mounted) return;
    if (amount >= 101 && amount <= 1000) {
      setState(() {
        _isLoadingQr = false;
        _qrAvailable = true;
        _qrImageUrl = 'https://dreamonlinehub.club/uploads/photos/1785149229_QR.png';
        _qrId = 5;
        _rangeId = 2;
        _empId = widget.agencyId ?? 29;
        _qrMessage = null;
      });
    } else if (amount >= 1001 && amount <= 10000) {
      setState(() {
        _isLoadingQr = false;
        _qrAvailable = true;
        _qrImageUrl = 'https://dreamonlinehub.club/uploads/photos/1785149209_QR.png';
        _qrId = 4;
        _rangeId = 3;
        _empId = widget.agencyId ?? 29;
        _qrMessage = null;
      });
    } else if (amount >= 1 && amount <= 100) {
      setState(() {
        _isLoadingQr = false;
        _qrAvailable = true;
        _qrImageUrl = 'https://dreamonlinehub.club/uploads/photos/1784640233_QR.png';
        _qrId = 1;
        _rangeId = 1;
        _empId = widget.agencyId ?? 29;
        _qrMessage = null;
      });
    } else {
      setState(() {
        _isLoadingQr = false;
        _qrAvailable = false;
        _qrMessage = 'Only Cash Transaction Available.';
        _qrImageUrl = null;
        _qrId = null;
        _rangeId = null;
        _empId = null;
      });
    }
  }

  Future<void> _onClickBook(String bookName) async {
    try {
      final targetBookId = _getBookId(bookName);
      final userId = await _resolveUserId();
      final apiClient = ApiClient();
      await apiClient.post(
        ApiEndpoints.getQrCode,
        options: Options(validateStatus: (status) => status != null && status < 500),
        data: {
          'action': 'click_on_book',
          'user_id': userId,
          'book_id': targetBookId,
        },
      );
    } catch (_) {
      // Silent catch for background click tracker
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    _txnIdController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _selectedScreenshot = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to select screenshot: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _submitForm() async {
    if (_selectedBook == null || _selectedBook!.isEmpty) {
      _showIssueDialog('Validation Issue', 'Please select a target book market before submitting.');
      return;
    }
    final amountText = _amountController.text.trim();
    final parsedAmount = double.tryParse(amountText);
    if (parsedAmount == null || parsedAmount <= 0) {
      _showIssueDialog('Validation Issue', 'Please enter a valid recharge amount (e.g. ₹500).');
      return;
    }
    final txnId = _txnIdController.text.trim();
    if (txnId.isEmpty) {
      _showIssueDialog('Validation Issue', 'Please enter the 12-digit UTR or Transaction ID.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final apiClient = ApiClient();
      final targetBookId = _getBookId(_selectedBook);
      final userId = await _resolveUserId();

      // Encode screenshot image to base64 if selected
      String imageBase64 = '';
      if (_selectedScreenshot != null && await _selectedScreenshot!.exists()) {
        final bytes = await _selectedScreenshot!.readAsBytes();
        final ext = _selectedScreenshot!.path.split('.').last.toLowerCase();
        final mimeType = ext == 'png' ? 'png' : (ext == 'jpg' || ext == 'jpeg' ? 'jpeg' : 'png');
        imageBase64 = 'data:image/$mimeType;base64,${base64Encode(bytes)}';
      }

      // Post recharge_by_user action to database API
      final response = await apiClient.post(
        ApiEndpoints.getQrCode,
        options: Options(validateStatus: (status) => status != null && status < 500),
        data: {
          'action': 'recharge_by_user',
          'user_id': userId,
          'qr_id': _qrId ?? 3,
          'range_id': _rangeId ?? 1,
          'amount': parsedAmount,
          'emp_id': _empId ?? widget.agencyId,
          'book_id': targetBookId,
          'transection_id': txnId,
          'image': imageBase64,
        },
      );

      if (!mounted) return;

      final data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true) {
        final successMsg = data['message']?.toString() ?? 'Recharge Request Submitted Successfully!';
        final rechargeId = data['recharge_id'];

        final newRecord = RechargeRecordModel(
          id: rechargeId != null ? '#$rechargeId' : '#${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
          bookName: _selectedBook!,
          transactionDetails: 'Txn: $txnId • ₹${parsedAmount.toStringAsFixed(2)}',
          amount: parsedAmount,
          status: 'EMPLOYEE-PENDING',
          date: 'Just now',
        );

        final agentId = await _saveRechargeToChatHistory(newRecord, txnId);

        setState(() {
          _isSubmitting = false;
          _txnIdController.clear();
          _selectedScreenshot = null;
        });

        if (!mounted) return;
        _showSuccessDialog(successMsg, newRecord, agentId);
      } else {
        final errMsg = (data is Map<String, dynamic> && data['message'] != null)
            ? data['message'].toString()
            : 'Failed to submit recharge request. Please verify transaction details and try again.';
        setState(() => _isSubmitting = false);
        _showIssueDialog('Submission Failed', errMsg);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      String errMsg = 'Failed to submit recharge request. Please check your internet connection.';
      if (e is ServerException) {
        errMsg = e.message;
      } else if (e is NetworkException) {
        errMsg = e.message;
      }
      _showIssueDialog('Network / Server Issue', errMsg);
    }
  }

  Future<String> _saveRechargeToChatHistory(RechargeRecordModel record, String txnId) async {
    final secureStorage = SecureStorageService();
    final storedAgentId = await secureStorage.read(StorageKeys.chatAgentId);
    final chatEmailId = await secureStorage.read(StorageKeys.chatEmailId) ?? '';
    final currentUser = LocalStorageRepositoryImpl().getUser();
    final userEmail = (chatEmailId.isNotEmpty)
        ? chatEmailId
        : ((currentUser?.email != null && currentUser!.email.isNotEmpty)
            ? currentUser.email
            : (currentUser?.id ?? 'user'));

    final rawUserAgency = currentUser?.agencyId;
    final validUserAgency = (rawUserAgency != null &&
            rawUserAgency.isNotEmpty &&
            rawUserAgency != 'null' &&
            rawUserAgency != '0')
        ? rawUserAgency
        : ((storedAgentId != null &&
                storedAgentId.isNotEmpty &&
                storedAgentId != 'null')
            ? storedAgentId
            : 'ADMIN-1');

    final agentId = (validUserAgency.startsWith('AGENCY-') || validUserAgency.toUpperCase().contains('ADMIN') || validUserAgency.contains('@'))
        ? validUserAgency
        : 'AGENCY-$validUserAgency';

    final conversationId = ApiEndpoints.buildConversationId(agentId, userEmail);

    final chatText = '📥 RECHARGE DEPOSIT REQUEST SUBMITTED\n'
        '• User ID: ${currentUser?.email ?? currentUser?.id ?? currentUser?.name ?? ""}\n'
        '• QR ID: ${_qrId ?? "N/A"}\n'
        '• Range ID: ${_rangeId ?? "N/A"}\n'
        '• Amount: ₹${record.amount.toStringAsFixed(0)}\n'
        '• Employee ID: ${_empId ?? widget.agencyId ?? await _resolveAgencyId()}\n'
        '• Book ID: ${_getBookId(_selectedBook)} (${record.bookName})\n'
        '• Transaction ID: $txnId\n'
        '• Payment Proof: ${_selectedScreenshot != null ? "[Screenshot Attached]" : "Not Attached"}';

    final repo = LocalStorageRepositoryImpl();
    await repo.saveSubmittedRecharge(record);
    widget.onRechargeSubmitted?.call(record);

    final newChatMsg = ChatMessageModel(
      id: 'recharge_${DateTime.now().millisecondsSinceEpoch}',
      senderId: 'me',
      receiverId: agentId,
      message: chatText,
      timestamp: DateTime.now(),
      isMe: true,
      status: 'sent',
      type: 'text',
    );

    // Save under all target keys so any chat view or cached load renders it
    final targetKeys = {agentId, conversationId, userEmail};
    for (final key in targetKeys) {
      final existingMsgs = repo.getCachedMessages(key);
      if (!existingMsgs.any((m) => m.id == newChatMsg.id)) {
        existingMsgs.add(newChatMsg);
        await repo.saveMessages(key, existingMsgs);
      }
    }

    final dto = SendMessageRequestDto(
      conversationId: conversationId,
      recipientId: agentId,
      type: 'text',
      text: chatText,
    );

    // 1. Post to Chat Server REST API so server stores it permanently in database
    try {
      await ChatApiClient.instance.post(
        ApiEndpoints.conversationMessages(conversationId),
        data: dto.toJson(),
      );
    } catch (_) {}

    // 2. Emit over Socket.IO for live agency screen updates
    try {
      if (SocketService.instance.isConnected) {
        SocketService.instance.emit(SocketEvents.sendMessage, dto.toJson());
        SocketService.instance.emit(SocketEvents.sendMessageLegacy, dto.toJson());
      }
    } catch (_) {}

    // Add to active ChatProvider if mounted
    if (mounted) {
      try {
        final chatProvider = Provider.of<ChatProvider>(context, listen: false);
        chatProvider.addRealtimeMessage(newChatMsg);
      } catch (_) {}
    }

    return agentId;
  }

  void _showSuccessDialog(String message, RechargeRecordModel record, String agentId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.25),
                    blurRadius: 30,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Glowing Animated Checkmark Badge
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      border: Border.all(
                        color: const Color(0xFF10B981),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.4),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF10B981),
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Recharge Successful!',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Transaction Summary Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildSummaryRow('Book Market', record.bookName, isDark),
                        const SizedBox(height: 8),
                        _buildSummaryRow('Amount', '₹${record.amount.toStringAsFixed(2)}', isDark, isHighlight: true),
                        const SizedBox(height: 8),
                        _buildSummaryRow('Transaction UTR', record.transactionDetails.replaceAll(RegExp(r'Txn:\s*|\s*•.*'), ''), isDark),
                        const SizedBox(height: 8),
                        _buildSummaryRow('Status', 'Pending Agency Approval', isDark, statusColor: const Color(0xFFF59E0B)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Primary Action Button: VIEW IN CHATING SCREEN
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(dialogContext); // Close dialog
                        Navigator.pop(context); // Close bottom sheet
                        context.push('/chat/$agentId'); // Navigate to chat screen
                      },
                      icon: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 18),
                      label: const Text(
                        'VIEW IN CHAT SCREEN',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 4,
                        shadowColor: const Color(0xFF7C3AED).withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Secondary Action Button: DONE
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(dialogContext); // Close dialog
                        Navigator.pop(context); // Close recharge bottom sheet
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? Colors.white70 : const Color(0xFF64748B),
                        side: BorderSide(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'DONE',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showIssueDialog(String title, String errorMessage) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.25),
                    blurRadius: 30,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Glowing Warning / Issue Badge
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                      border: Border.all(
                        color: const Color(0xFFEF4444),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      color: Color(0xFFEF4444),
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Error Message Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFEF4444),
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Try Again Button
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 4,
                        shadowColor: const Color(0xFFEF4444).withValues(alpha: 0.4),
                      ),
                      child: const Text(
                        'TRY AGAIN',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, String value, bool isDark, {bool isHighlight = false, Color? statusColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: isHighlight ? 14.5 : 12.5,
              fontWeight: isHighlight || statusColor != null ? FontWeight.w900 : FontWeight.w700,
              color: statusColor ?? (isHighlight ? const Color(0xFF10B981) : (isDark ? Colors.white : const Color(0xFF0F172A))),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF070D22),
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0D1736),
            Color(0xFF070D22),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: const Color(0xFF0066FF).withValues(alpha: 0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0066FF).withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(isSmallScreen ? 14 : 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Adaptive Header Section
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF0066FF),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0066FF).withValues(alpha: 0.5),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.flash_on_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recharge Now',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: isSmallScreen ? 18 : 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Add balance to your account for gaming',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              // Secure Chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A1B44),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF0066FF).withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      color: Color(0xFF00B2FF),
                      size: 13,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Secure',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF00B2FF),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 2. Select Book Dropdown
          _buildRefLabel('SELECT BOOK *'),
          const SizedBox(height: 8),
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF050B1E),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF0066FF).withValues(alpha: 0.4),
                width: 1.2,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedBook,
                hint: Row(
                  children: [
                    const Icon(Icons.menu_book_rounded, size: 18, color: Color(0xFF00B2FF)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _books.isEmpty
                            ? 'No Book Account Available (Get ID First)'
                            : 'Select Book Market',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: _books.isEmpty
                              ? const Color(0xFFEF4444)
                              : Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ],
                ),
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF00B2FF)),
                dropdownColor: const Color(0xFF070D22),
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                onChanged: (val) {
                  setState(() => _selectedBook = val);
                  _fetchQrCode();
                  if (val != null) {
                    _onClickBook(val);
                  }
                },
                items: [
                  for (final book in _books)
                    DropdownMenuItem<String>(
                      value: book,
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 16, color: Color(0xFF00B2FF)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              book,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 3. Recharge Amount Input & Quick Chips
          _buildRefLabel('RECHARGE AMOUNT *'),
          const SizedBox(height: 8),
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF050B1E),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF0066FF).withValues(alpha: 0.4),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.currency_rupee_rounded,
                  size: 20,
                  color: Color(0xFF00B2FF),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    cursorColor: const Color(0xFF00B2FF),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter Amount (e.g. 500)',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                      filled: false,
                      fillColor: Colors.transparent,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Quick Amount Presets (Scrollable Row for 100% Mobile Responsiveness)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                for (final amt in [100, 500, 1000, 2000, 5000, 10000])
                  Builder(builder: (ctx) {
                    final currentVal = double.tryParse(_amountController.text.trim()) ?? 0;
                    final isSelected = currentVal == amt.toDouble();
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _amountController.text = amt.toString();
                          });
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF0066FF) : const Color(0xFF050B1E),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF00B2FF)
                                  : const Color(0xFF0066FF).withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '₹$amt',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: isSelected ? Colors.white : const Color(0xFF00B2FF),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // QR Code Card dynamically fetched from Backend
          _buildQrCodeCard(isDark),
          const SizedBox(height: 16),

          // 4. Transaction ID / UTR Input
          _buildRefLabel('TRANSACTION ID / UTR *'),
          const SizedBox(height: 8),
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF050B1E),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF0066FF).withValues(alpha: 0.4),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.receipt_long_rounded,
                  size: 20,
                  color: Color(0xFF00B2FF),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _txnIdController,
                    cursorColor: const Color(0xFF00B2FF),
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter 12-digit UTR or Txn ID',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                      filled: false,
                      fillColor: Colors.transparent,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 5. Upload Screenshot Area
          _buildRefLabel('UPLOAD PAYMENT PROOF SCREENSHOT *'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF050B1E),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF0066FF).withValues(alpha: 0.4),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A183C),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF00B2FF).withValues(alpha: 0.6),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.cloud_upload_outlined,
                    color: Color(0xFF00B2FF),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedScreenshot != null
                            ? _selectedScreenshot!.path.split('/').last
                            : 'Choose Screenshot File',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'JPG or PNG image proof',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Choose File Button
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0066FF), Color(0xFF0044CE)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0066FF).withValues(alpha: 0.4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _pickImage,
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.file_upload_outlined,
                              color: Colors.white,
                              size: 15,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Choose File',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 6. Info Notice Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0066FF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF0066FF).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF00B2FF),
                  size: 17,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Please verify payment transaction UTR before submitting.',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Colors.white.withValues(alpha: 0.7),
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 7. Submit Button (Recharge Now)
          Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              gradient: const LinearGradient(
                colors: [Color(0xFF0077FF), Color(0xFF0044CE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0066FF).withValues(alpha: 0.45),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isSubmitting ? null : _submitForm,
                borderRadius: BorderRadius.circular(25),
                child: _isSubmitting
                    ? const Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Recharge Now',
                            style: GoogleFonts.outfit(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrCodeCard(bool isDark) {
    if (_isLoadingQr) {
      return Container(
        margin: const EdgeInsets.only(top: 14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B1833) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFF97316).withValues(alpha: 0.3),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: Color(0xFFF97316),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Fetching QR code from backend...',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      );
    }

    if (_qrAvailable == false && _qrMessage != null) {
      return Container(
        margin: const EdgeInsets.only(top: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2D1F18) : const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFF97316).withValues(alpha: 0.4),
            width: 1.2,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF97316).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.info_outline_rounded,
                color: Color(0xFFF97316),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _qrMessage!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFF97316),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'No online QR code found for this amount range. Please make a cash deposit with your agency.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (_qrAvailable == true && _qrImageUrl != null && _qrImageUrl!.isNotEmpty) {
      return Container(
        margin: const EdgeInsets.only(top: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0A183C), Color(0xFF050B1E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF10B981).withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top Badge Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.qr_code_2_rounded,
                        color: Colors.white,
                        size: 15,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'SCAN & PAY VIA UPI',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF10B981),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Text(
                    'INSTANT QR',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // QR Code Image Container
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (dialogCtx) => Dialog(
                    backgroundColor: Colors.transparent,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(
                              _qrImageUrl!,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.white,
                                padding: const EdgeInsets.all(20),
                                child: const Icon(Icons.broken_image, size: 60, color: Colors.grey),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
                            onPressed: () => Navigator.pop(dialogCtx),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _qrImageUrl!,
                    width: 165,
                    height: 165,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return SizedBox(
                        width: 165,
                        height: 165,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 165,
                        height: 165,
                        color: Colors.grey[100],
                        alignment: Alignment.center,
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.qr_code_scanner_rounded, size: 40, color: Colors.grey),
                            SizedBox(height: 6),
                            Text('QR Image', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap QR code to zoom in',
              style: TextStyle(
                fontSize: 10.5,
                color: Colors.white54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildRefLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: Color(0xFF00B2FF),
        letterSpacing: 0.5,
      ),
    );
  }
}
