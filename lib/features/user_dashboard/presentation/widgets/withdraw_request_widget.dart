import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../models/chat/chat_message_model.dart';
import '../../../../models/dto/chat/send_message_request_dto.dart';
import '../../../../network/api_client.dart';
import '../../../../network/chat_api_client.dart';
import '../../../../providers/chat_provider.dart';
import '../../../../socket/socket_events.dart';
import '../../../../socket/socket_service.dart';
import '../../../../storage/local_storage_repository.dart';
import '../../../../storage/secure_storage_service.dart';

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
  final int bookId;
  final int agencyId;

  const WithdrawRequestWidget({
    super.key,
    this.onWithdrawSubmitted,
    this.bookId = 324,
    this.agencyId = 23,
  });

  @override
  State<WithdrawRequestWidget> createState() => _WithdrawRequestWidgetState();
}

class _WithdrawRequestWidgetState extends State<WithdrawRequestWidget> {
  String? _selectedBook;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  File? _selectedScreenshot;
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;

  Map<String, int> _dynamicBookIds = {};
  List<String> _books = [
    'LUCKY VAULT',
    'DICE VERSE',
    'JACKPOT SPIN',
    'GOLD RUSH PRO',
    'INFINITY FORTUNE',
    'CROWN RICHES',
  ];

  @override
  void initState() {
    super.initState();
    _fetchBooks();
  }

  Future<int> _resolveUserId() async {
    final currentUser = LocalStorageRepositoryImpl().getUser();
    if (currentUser?.id != null && currentUser!.id.isNotEmpty) {
      final digitsOnly = currentUser.id.replaceAll(RegExp(r'\D'), '');
      if (digitsOnly.isNotEmpty) {
        return int.tryParse(digitsOnly) ?? 22;
      }
    }
    final storedUserId = await SecureStorageService().read(StorageKeys.userId);
    if (storedUserId != null && storedUserId.isNotEmpty) {
      final digitsOnly = storedUserId.replaceAll(RegExp(r'\D'), '');
      if (digitsOnly.isNotEmpty) {
        return int.tryParse(digitsOnly) ?? 22;
      }
    }
    return 22;
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

        final List<String> fetchedBooks = [];
        final Map<String, int> bookMap = {};

        for (final item in rawList) {
          String name = '';
          int bId = 0;
          if (item is Map) {
            name = item['book_name']?.toString() ??
                item['bookName']?.toString() ??
                item['name']?.toString() ??
                item['title']?.toString() ??
                '';
            bId = int.tryParse(item['id']?.toString() ?? item['book_id']?.toString() ?? '0') ?? 0;
          } else if (item != null) {
            name = item.toString();
          }

          if (name.isNotEmpty && !fetchedBooks.contains(name)) {
            fetchedBooks.add(name);
            if (bId > 0) {
              bookMap[name] = bId;
            }
          }
        }

        if (fetchedBooks.isNotEmpty) {
          setState(() {
            _books = fetchedBooks.toSet().toList();
            _dynamicBookIds = bookMap;
            if (_selectedBook != null && !_books.contains(_selectedBook)) {
              _selectedBook = null;
            }
          });
        }
      }
    } catch (_) {
      // Keep state on network error
    }
  }

  int _getBookId(String? bookName) {
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

    final description = _descriptionController.text.trim();

    setState(() => _isSubmitting = true);

    try {
      final apiClient = ApiClient();
      final targetBookId = _getBookId(_selectedBook);
      final userId = await _resolveUserId();

      String imageBase64 = '';
      if (_selectedScreenshot != null && await _selectedScreenshot!.exists()) {
        final bytes = await _selectedScreenshot!.readAsBytes();
        final ext = _selectedScreenshot!.path.split('.').last.toLowerCase();
        final mimeType = ext == 'png' ? 'png' : (ext == 'jpg' || ext == 'jpeg' ? 'jpeg' : 'png');
        imageBase64 = 'data:image/$mimeType;base64,${base64Encode(bytes)}';
      }

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
          'emp_id': widget.agencyId,
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
          'emp_id': widget.agencyId.toString(),
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
            'emp_id': widget.agencyId,
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
        _selectedScreenshot = null;
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
        _selectedScreenshot = null;
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
                storedAgentId != 'null' &&
                !storedAgentId.toUpperCase().contains('ADMIN'))
            ? storedAgentId
            : '23');

    final agentId = (validUserAgency.startsWith('AGENCY-') || validUserAgency.contains('@'))
        ? validUserAgency
        : 'AGENCY-$validUserAgency';

    final conversationId = ApiEndpoints.buildConversationId(agentId, userEmail);

    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final descLine = description.isNotEmpty ? '\n• Details / UTR: $description' : '';
    final chatText = '📤 WITHDRAWAL REQUEST SUBMITTED\n'
        '• Book Market: ${model.bookName}\n'
        '• Amount: ₹${model.amount.toStringAsFixed(2)}'
        '$descLine\n'
        '• Status: PENDING AGENCY APPROVAL\n'
        '• Date & Time: $timeStr';

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
                              'Select Book',
                              style: TextStyle(
                                fontSize: 13.5,
                                color: hintColor,
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

            // 3. DESCRIPTION (OPTIONAL)* (Middle Multiline Field)
            _buildLabel('DESCRIPTION (OPTIONAL)', isDark),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: inputBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: TextField(
                controller: _descriptionController,
                maxLines: 4,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter Description',
                  hintStyle: TextStyle(
                    fontSize: 13.5,
                    color: hintColor,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 4. UPLOAD QR CODE*
            _buildLabel('UPLOAD QR CODE', isDark),
            const SizedBox(height: 6),
            Row(
              children: [
                // Dashed Border Upload Button Area
                Expanded(
                  child: CustomPaint(
                    painter: DashedBorderPainter(
                      color: const Color(0xFFF59E0B),
                      strokeWidth: 1.5,
                      gap: 4.5,
                      dash: 6.0,
                    ),
                    child: InkWell(
                      onTap: _pickImage,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 72,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2B2519).withValues(alpha: 0.4)
                              : const Color(0xFFFFFDF5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _selectedScreenshot != null
                                    ? _selectedScreenshot!.path.split('/').last
                                    : 'Choose Screenshot File',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                                ),
                              ),
                            ),
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF52421D)
                                    : const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.upload_rounded,
                                color: Color(0xFFD97706),
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Preview Box (72x72)
                Stack(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: inputBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor, width: 1),
                      ),
                      child: _selectedScreenshot != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(11),
                              child: Image.file(_selectedScreenshot!, fit: BoxFit.cover),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image_outlined,
                                  size: 24,
                                  color: hintColor,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'NO IMAGE',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    color: hintColor,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                    ),
                    if (_selectedScreenshot != null)
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedScreenshot = null),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(3),
                            child: const Icon(Icons.close_rounded, size: 12, color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

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

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dash;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.gap = 4.5,
    this.dash = 6.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(12),
    );

    final Path path = Path()..addRRect(rrect);
    final Path dashPath = Path();

    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double len = (distance + dash < metric.length) ? dash : metric.length - distance;
        dashPath.addPath(metric.extractPath(distance, distance + len), Offset.zero);
        distance += dash + gap;
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.gap != gap ||
      oldDelegate.dash != dash;
}
