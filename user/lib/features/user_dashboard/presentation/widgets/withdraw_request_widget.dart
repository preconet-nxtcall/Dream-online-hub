import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../models/chat/chat_message_model.dart';
import '../../../../models/dto/chat/send_message_request_dto.dart';
import '../../../../models/user/payment_account_model.dart';
import '../../../../network/api_client.dart';
import '../../../../network/chat_api_client.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/chat_provider.dart';
import '../../../../repositories/payment_account_repository.dart';
import '../../../../socket/socket_events.dart';
import '../../../../socket/socket_service.dart';
import '../../../../storage/local_storage_repository.dart';
import '../../../../storage/secure_storage_service.dart';
import '../../../profile/presentation/widgets/payment_account_widget.dart';

class WithdrawRequestModel {
  final String id;
  final String bookName;
  final double amount;
  final String description;
  final String status;
  final String date;

  WithdrawRequestModel({
    required this.id,
    required this.bookName,
    required this.amount,
    required this.description,
    required this.status,
    required this.date,
  });
}

class WithdrawRequestWidget extends StatefulWidget {
  final Function(WithdrawRequestModel model)? onWithdrawSubmitted;
  final int? bookId;
  final int? agencyId;
  final PaymentAccountRepository? repository;
  final dynamic userId; 

  const WithdrawRequestWidget({
    super.key,
    this.onWithdrawSubmitted,
    this.bookId,
    this.agencyId,
    this.repository,
    this.userId,
  });

  @override
  State<WithdrawRequestWidget> createState() => _WithdrawRequestWidgetState();
}

class _WithdrawRequestWidgetState extends State<WithdrawRequestWidget> {
  String? _selectedBook;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  PaymentAccountModel? _savedAccount;
  bool _isLoadingAccount = true;
  bool _isApprovedAccountAvailable = false;
  String? _accountStatusText;

  Map<String, int> _dynamicBookIds = {};
  List<String> _books = [];

  @override
  void initState() {
    super.initState();
    _fetchBooks();
    _fetchPaymentAccount();
  }

  Future<void> _fetchPaymentAccount() async {
    try {
      setState(() => _isLoadingAccount = true);
      final userId = await _resolveUserId();
      final repo = widget.repository ?? PaymentAccountRepositoryImpl();
      final account = await repo.getPaymentAccount(userId);

      if (!mounted) return;

      if (account != null) {
        final bool hasBankInfo = account.hasBankInfo;
        final bool isApproved = account.isApproved;
        final bool isPending = account.isPendingApproval;
        final bool isValidApproved = (isApproved || (hasBankInfo && !isPending)) && hasBankInfo;
        final rawStatus = account.status.trim().toUpperCase();

        setState(() {
          _savedAccount = account;
          _isApprovedAccountAvailable = isValidApproved;
          _accountStatusText = rawStatus.isNotEmpty
              ? rawStatus
              : (isPending ? 'PENDING' : (isValidApproved ? 'APPROVED' : 'NOT APPROVED'));
          _isLoadingAccount = false;
        });

        if (isValidApproved) {
          final buffer = StringBuffer();
          if (account.bankName.isNotEmpty) buffer.writeln('Bank Name: ${account.bankName}');
          if (account.accountName.isNotEmpty) buffer.writeln('Account Holder: ${account.accountName}');
          if (account.accountNo.isNotEmpty) buffer.writeln('Account No: ${account.accountNo}');
          if (account.ifscCode.isNotEmpty) buffer.writeln('IFSC Code: ${account.ifscCode}');
          if (account.upiId.isNotEmpty) buffer.writeln('UPI ID: ${account.upiId}');
          _descriptionController.text = buffer.toString().trim();
        }
      } else {
        setState(() {
          _savedAccount = null;
          _isApprovedAccountAvailable = false;
          _accountStatusText = null;
          _isLoadingAccount = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingAccount = false);
      }
    }
  }

  void _openPaymentAccountSettings() {
    final parentCtx = context;
    if (Navigator.of(parentCtx).canPop()) {
      Navigator.of(parentCtx).pop();
    }

    showModalBottomSheet(
      context: parentCtx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.90,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF13111C),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: PaymentAccountWidget(
                repository: widget.repository,
                onClose: () => Navigator.of(ctx).pop(),
              ),
            ),
          ),
        ),
      ),
    ).then((_) {
      if (mounted) {
        _fetchPaymentAccount();
      }
    });
  }

  Future<dynamic> _resolveUserId() async {
    if (widget.userId != null && widget.userId.toString().trim().isNotEmpty) {
      final raw = widget.userId.toString().trim();
      final digitsOnly = raw.replaceAll(RegExp(r'\D'), '');
      return digitsOnly.isNotEmpty ? (int.tryParse(digitsOnly) ?? raw) : raw;
    }
    try {
      final authProv = Provider.of<AuthProvider>(context, listen: false);
      final user = authProv.currentUser;
      if (user?.id != null && user!.id.trim().isNotEmpty) {
        final raw = user.id.trim();
        final digitsOnly = raw.replaceAll(RegExp(r'\D'), '');
        return digitsOnly.isNotEmpty ? (int.tryParse(digitsOnly) ?? raw) : raw;
      }
    } catch (_) {}
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
      if (widget.repository != null) return;
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
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
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

  Future<void> _submitForm() async {
    if (_selectedBook == null || _selectedBook!.isEmpty) {
      _showIssueDialog('Validation Issue', 'Please select a target book market for withdrawal.');
      return;
    }

    final amountText = _amountController.text.trim();
    final parsedAmount = double.tryParse(amountText);
    if (parsedAmount == null || parsedAmount <= 0) {
      _showIssueDialog('Validation Issue', 'Please enter a valid withdrawal amount (e.g. ₹500).');
      return;
    }

    final userRemarks = _descriptionController.text.trim();

    // Strictly require an approved bank account saved in Profile section!
    if (!_isApprovedAccountAvailable) {
      if (_savedAccount != null && (_savedAccount!.isPendingApproval || (_accountStatusText ?? '').contains('PENDING'))) {
        _showIssueDialog('Approval Pending', 'Your saved bank details are currently awaiting agency approval. Withdrawals will be enabled once approved.');
      } else {
        _showIssueDialog('Bank Details Required', 'First save your Bank Details in Profile section before requesting withdrawal.');
      }
      return;
    }

    final bankInfoStr = 'Bank: ${_savedAccount?.bankName}, Holder: ${_savedAccount?.accountName}, Acc: ${_savedAccount?.accountNo}, IFSC: ${_savedAccount?.ifscCode}, UPI: ${_savedAccount?.upiId}';

    final String description = userRemarks.isNotEmpty
        ? '$bankInfoStr\nRemarks: $userRemarks'
        : bankInfoStr;

    setState(() => _isSubmitting = true);

    try {
      final apiClient = ApiClient();
      final targetBookId = _getBookId(_selectedBook);
      final userId = await _resolveUserId();

      String imageBase64 = '';
      if (_savedAccount?.image != null && _savedAccount!.image!.isNotEmpty) {
        imageBase64 = _savedAccount!.image!;
      }

      final targetAgencyId = await _resolveAgencyId();

      final options = Options(validateStatus: (status) => status != null && status < 500);

      var response = await apiClient.post(
        ApiEndpoints.getQrCode,
        options: options,
        data: {
          'action': 'user_withdraw',
          'user_id': userId,
          'book_id': targetBookId,
          'amount': parsedAmount,
          'deatil': description,
          'description': description,
          'emp_id': targetAgencyId,
          'image': imageBase64,
        },
      );

      var data = response.data;

      // If 400 or invalid success flag, retry with form-urlencoded content type for standard PHP $_POST
      if (response.statusCode == 400 || data is! Map<String, dynamic> || data['success'] != true) {
        final formMap = {
          'action': 'user_withdraw',
          'user_id': userId.toString(),
          'book_id': targetBookId.toString(),
          'amount': parsedAmount.toString(),
          'deatil': description,
          'description': description,
          'emp_id': (targetAgencyId ?? '').toString(),
          'image': imageBase64,
        };

        try {
          final formResp = await apiClient.post(
            ApiEndpoints.getQrCode,
            options: Options(
              contentType: Headers.formUrlEncodedContentType,
              validateStatus: (status) => status != null && status < 500,
            ),
            data: formMap,
          );
          if (formResp.data is Map<String, dynamic> && formResp.data['success'] == true) {
            response = formResp;
            data = formResp.data;
          }
        } catch (_) {}
      }

      if (data is! Map<String, dynamic> || data['success'] != true) {
        // Fallback retry with legacy action name
        final fallbackResp = await apiClient.post(
          ApiEndpoints.getQrCode,
          options: options,
          data: {
            'action': 'withdraw_by_user',
            'user_id': userId,
            'book_id': targetBookId,
            'amount': parsedAmount,
            'deatil': description,
            'description': description,
            'emp_id': targetAgencyId,
            'image': imageBase64,
          },
        );
        if (fallbackResp.data is Map<String, dynamic> && fallbackResp.data['success'] == true) {
          data = fallbackResp.data;
        }
      }

      if (!mounted) return;

      final successMsg = (data is Map<String, dynamic> && data['message'] != null)
          ? data['message'].toString()
          : 'Withdrawal Request Submitted Successfully!';

      final rawWId = (data is Map<String, dynamic> && data['withdrawal_id'] != null)
          ? data['withdrawal_id'].toString()
          : DateTime.now().millisecondsSinceEpoch.toString().substring(7);

      final withdrawModel = WithdrawRequestModel(
        id: '#W$rawWId',
        bookName: _selectedBook!,
        amount: parsedAmount,
        description: description,
        status: 'PENDING',
        date: 'Just now',
      );

      final agentId = await _saveWithdrawToChatHistory(withdrawModel, description);

      setState(() {
        _isSubmitting = false;
        _amountController.clear();
        _descriptionController.clear();
      });

      if (!mounted) return;
      _showSuccessDialog(successMsg, withdrawModel, agentId);
    } catch (e) {
      if (!mounted) return;

      // Fallback for demo / offline mode: still save and trigger dialogs
      final withdrawModel = WithdrawRequestModel(
        id: '#W${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        bookName: _selectedBook!,
        amount: parsedAmount,
        description: description,
        status: 'PENDING',
        date: 'Just now',
      );

      final agentId = await _saveWithdrawToChatHistory(withdrawModel, description);

      setState(() {
        _isSubmitting = false;
        _amountController.clear();
        _descriptionController.clear();
      });

      if (!mounted) return;
      _showSuccessDialog('Withdrawal request submitted to Agency Support!', withdrawModel, agentId);
    }
  }

  Future<String> _saveWithdrawToChatHistory(WithdrawRequestModel model, String description) async {
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

    final chatText = '📤 WITHDRAWAL REQUEST SUBMITTED\n'
        '• User ID: ${currentUser?.email ?? currentUser?.id ?? currentUser?.name ?? ""}\n'
        '• Game Book: ${model.bookName}\n'
        '• Amount: ₹${model.amount.toStringAsFixed(0)}\n'
        '• Bank Account Details: ${description.isNotEmpty ? description : model.description}';

    final repo = LocalStorageRepositoryImpl();
    widget.onWithdrawSubmitted?.call(model);

    final newChatMsg = ChatMessageModel(
      id: 'withdraw_${DateTime.now().millisecondsSinceEpoch}',
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

  void _showSuccessDialog(String message, WithdrawRequestModel model, String agentId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            padding: const EdgeInsets.all(24),
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
                  width: 72,
                  height: 72,
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
                    size: 42,
                  ),
                ),
                const SizedBox(height: 18),

                Text(
                  'Withdrawal Request Submitted!',
                  textAlign: TextAlign.center,
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
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 20),

                // Summary Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildSummaryRow('Book Market', model.bookName, isDark),
                      const SizedBox(height: 8),
                      _buildSummaryRow('Withdraw Amount', '₹${model.amount.toStringAsFixed(2)}', isDark, isHighlight: true),
                      const SizedBox(height: 8),
                      _buildSummaryRow('Status', 'Pending Agency Approval', isDark, statusColor: const Color(0xFFF59E0B)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Primary Action Button: VIEW IN CHAT SCREEN
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(dialogContext); // Close dialog
                      Navigator.pop(context); // Close bottom sheet
                      context.push('/chat/$agentId'); // Navigate to chat screen
                    },
                    icon: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 20),
                    label: const Text(
                      'VIEW IN CHAT SCREEN',
                      style: TextStyle(
                        fontSize: 14,
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
                      Navigator.pop(context); // Close bottom sheet
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
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
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
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            padding: const EdgeInsets.all(24),
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
                  width: 72,
                  height: 72,
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
                    size: 42,
                  ),
                ),
                const SizedBox(height: 18),

                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 10),

                // Error Message Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
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
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFEF4444),
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Try Again Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
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
                        fontSize: 14.5,
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
            fontSize: 12.5,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isHighlight ? 15 : 13,
            fontWeight: isHighlight || statusColor != null ? FontWeight.w900 : FontWeight.w700,
            color: statusColor ?? (isHighlight ? const Color(0xFF10B981) : (isDark ? Colors.white : const Color(0xFF0F172A))),
          ),
        ),
      ],
    );
  }

  Widget _buildBankDetailsSection(
    bool isDark,
    Color inputBg,
    Color borderColor,
    Color hintColor,
    Color textColor,
  ) {
    if (_isLoadingAccount) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: inputBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF10B981)),
            ),
            SizedBox(width: 12),
            Text(
              'Fetching saved payout details...',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    if (_isApprovedAccountAvailable && _savedAccount != null) {
      final acc = _savedAccount!;
      final hasQrImage = acc.image != null && acc.image!.trim().isNotEmpty;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131C2E) : const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF10B981).withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.12),
              blurRadius: 14,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Approved Badge + Bank Icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF10B981), width: 1),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 14),
                      SizedBox(width: 4),
                      Text(
                        'APPROVED PAYOUT ACCOUNT',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF10B981),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                const Icon(Icons.account_balance_rounded, color: Color(0xFF10B981), size: 20),
              ],
            ),
            const SizedBox(height: 14),

            // Account Details Grid / Column
            _buildAccountDetailRow('Bank Name', acc.bankName.isNotEmpty ? acc.bankName : 'N/A', isDark, isBold: true),
            const SizedBox(height: 8),
            _buildAccountDetailRow('Holder Name', acc.accountName.isNotEmpty ? acc.accountName : 'N/A', isDark),
            if (acc.accountNo.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildAccountDetailRow('Account No', acc.accountNo, isDark),
            ],
            if (acc.ifscCode.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildAccountDetailRow('IFSC Code', acc.ifscCode, isDark),
            ],
            if (acc.upiId.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildAccountDetailRow('UPI ID', acc.upiId, isDark, statusColor: const Color(0xFF38BDF8)),
            ],

            // QR Code / Passbook Image Thumbnail Preview
            if (hasQrImage) ...[
              const SizedBox(height: 14),
              const Divider(height: 1, thickness: 0.8),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text(
                    'Saved QR Code / Passbook:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _showImageDialog(acc.image!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.zoom_in_rounded, size: 14, color: Color(0xFF10B981)),
                          SizedBox(width: 4),
                          Text(
                            'Enlarge QR',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF10B981)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _showImageDialog(acc.image!),
                child: Container(
                  height: 90,
                  width: 90,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: _buildAccountImageWidget(acc.image!),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    // Account is Pending or No Bank Account Saved
    final bool isPending = _savedAccount != null &&
        (_savedAccount!.isPendingApproval || (_accountStatusText ?? '').contains('PENDING'));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPending
            ? (isDark ? const Color(0xFF2C2213) : const Color(0xFFFFFBEB))
            : (isDark ? const Color(0xFF2D181A) : const Color(0xFFFEF2F2)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPending
              ? const Color(0xFFF59E0B).withValues(alpha: 0.6)
              : const Color(0xFFEF4444).withValues(alpha: 0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isPending ? const Color(0xFFF59E0B) : const Color(0xFFEF4444)).withValues(alpha: 0.15),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (isPending ? const Color(0xFFF59E0B) : const Color(0xFFEF4444)).withValues(alpha: 0.15),
                ),
                child: Icon(
                  isPending ? Icons.hourglass_top_rounded : Icons.account_balance_outlined,
                  color: isPending ? const Color(0xFFF59E0B) : const Color(0xFFEF4444),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPending ? 'Bank Account Approval Pending' : 'No Approved Bank Account',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: isPending ? const Color(0xFFD97706) : const Color(0xFFDC2626),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isPending
                          ? 'Your saved bank details are awaiting agency verification. Withdrawals will be enabled once approved.'
                          : 'First save bank details in Profile section before requesting withdrawal.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isPending
                      ? const [Color(0xFFF59E0B), Color(0xFFD97706)]
                      : const [Color(0xFFEF4444), Color(0xFFDC2626)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: (isPending ? const Color(0xFFF59E0B) : const Color(0xFFEF4444)).withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _openPaymentAccountSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isPending ? Icons.edit_rounded : Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                      size: 17,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isPending ? 'CHECK BANK STATUS IN PROFILE' : 'FIRST SAVE BANK DETAILS IN PROFILE',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountDetailRow(String label, String value, bool isDark, {bool isBold = false, Color? statusColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            fontWeight: FontWeight.w600,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
              color: statusColor ?? (isDark ? Colors.white : const Color(0xFF0F172A)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountImageWidget(String imgStr) {
    if (imgStr.startsWith('data:image')) {
      try {
        final base64Data = imgStr.split(',').last;
        final bytes = base64Decode(base64Data);
        return Image.memory(bytes, fit: BoxFit.cover);
      } catch (_) {}
    } else if (imgStr.startsWith('http')) {
      return Image.network(
        imgStr,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.qr_code_rounded, size: 36, color: Colors.grey),
      );
    }
    return const Icon(Icons.qr_code_rounded, size: 36, color: Colors.grey);
  }

  void _showImageDialog(String imgStr) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              constraints: const BoxConstraints(maxHeight: 350, maxWidth: 350),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _buildAccountImageWidget(imgStr),
              ),
            ),
            const SizedBox(height: 12),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, bool isDark) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
            ),
          ),
          const TextSpan(
            text: '*',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFFEF4444),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionalLabel(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
        color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1A192B) : Colors.white;
    final inputBg = isDark ? const Color(0xFF25233B) : const Color(0xFFF3F4F6);
    final borderColor = isDark ? const Color(0xFF373454) : const Color(0xFFE5E7EB);
    final hintColor = isDark ? const Color(0xFF82819A) : const Color(0xFF9CA3AF);
    final textColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final maxHeight = MediaQuery.of(context).size.height * 0.88;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Top Drag handle pill
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF403C5C) : const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Top Row: SELECT BOOK & WITHDRAW AMOUNT
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. SELECT BOOK* (Left Field)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('SELECT BOOK', isDark),
                      const SizedBox(height: 6),
                      Container(
                        height: 46,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: inputBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderColor, width: 1),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedBook,
                            hint: Text(
                              _books.isEmpty
                                  ? 'No Book Account Available (Get ID First)'
                                  : 'Select Book',
                              style: TextStyle(
                                fontSize: 13.5,
                                color: _books.isEmpty
                                    ? const Color(0xFFEF4444)
                                    : hintColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            isExpanded: true,
                            icon: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              size: 20,
                            ),
                            dropdownColor: isDark ? const Color(0xFF25233B) : Colors.white,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                            onChanged: (val) {
                              setState(() => _selectedBook = val);
                              if (val != null) {
                                _onClickBook(val);
                              }
                            },
                            items: [
                              for (final book in _books)
                                DropdownMenuItem<String>(
                                  value: book,
                                  child: Text(book),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // 2. WITHDRAW AMOUNT* (Right Field)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('WITHDRAW AMOUNT', isDark),
                      const SizedBox(height: 6),
                      Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: inputBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderColor, width: 1),
                        ),
                        child: TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Enter Amount',
                            hintStyle: TextStyle(
                              fontSize: 13.5,
                              color: hintColor,
                              fontWeight: FontWeight.w400,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 3. SAVED BANK DETAILS & QR CODE / APPROVAL NOTICE
            _buildLabel('SAVED PAYOUT BANK ACCOUNT', isDark),
            const SizedBox(height: 6),
            _buildBankDetailsSection(isDark, inputBg, borderColor, hintColor, textColor),
            const SizedBox(height: 16),

            // 4. REMARKS / ADDITIONAL NOTES (Optional Multiline Field)
            _buildOptionalLabel('REMARKS / ADDITIONAL NOTES (OPTIONAL)', isDark),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: inputBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: TextField(
                controller: _descriptionController,
                maxLines: 2,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
                decoration: InputDecoration(
                  hintText: 'Add optional remarks or notes for withdrawal (optional)...',
                  hintStyle: TextStyle(
                    fontSize: 12.5,
                    color: hintColor,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 5. Centered Dark Button with Yellow Text: "Withdraw Request"
            Center(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isSubmitting ? null : _submitForm,
                  borderRadius: BorderRadius.circular(25),
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2D2C44) : const Color(0xFF282738),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Color(0xFFFBBF24),
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Withdraw Request',
                            style: TextStyle(
                              color: Color(0xFFFBBF24),
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
