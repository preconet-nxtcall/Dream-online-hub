import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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

  bool _hasPendingWithdrawal = false;

  @override
  void initState() {
    super.initState();
    _fetchBooks();
    _fetchPaymentAccount();
    _checkPendingWithdrawalStatus();
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
        final bool isRejected = account.isRejected;
        final bool isValidApproved = isApproved && hasBankInfo && !isRejected;
        final rawStatus = account.status.trim().toUpperCase();

        setState(() {
          _savedAccount = account;
          _isApprovedAccountAvailable = isValidApproved;
          _accountStatusText = rawStatus.isNotEmpty
              ? rawStatus
              : (isPending ? 'PENDING' : (isRejected ? 'REJECTED' : (isValidApproved ? 'APPROVED' : 'NOT APPROVED')));
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

  Future<bool> _checkPendingWithdrawalStatus({bool silent = false}) async {
    try {
      final userId = await _resolveUserId();
      if (userId == null) {
        return _hasPendingWithdrawal;
      }

      final apiClient = ApiClient();
      final response = await apiClient.post(
        ApiEndpoints.getQrCode,
        options: Options(validateStatus: (status) => status != null && status < 500),
        data: {
          'action': 'withdraw_records',
          'user_id': userId,
          'status_type': 'all',
        },
      );

      if (!mounted) return _hasPendingWithdrawal;

      bool foundPending = false;
      bool backendChecked = false;
      final data = response.data;
      List rawList = [];

      if (data is Map<String, dynamic>) {
        final isSuccess = data['success'] == true ||
            data['success'] == 1 ||
            data['success'] == '1' ||
            data['success'] == 'true';

        if (isSuccess || data['data'] != null || data['withdrawals'] != null || data['categorized'] != null) {
          backendChecked = true;
          if (data['data'] is List && (data['data'] as List).isNotEmpty) {
            rawList.addAll(data['data'] as List);
          } else if (data['withdrawals'] is List && (data['withdrawals'] as List).isNotEmpty) {
            rawList.addAll(data['withdrawals'] as List);
          } else if (data['records'] is List && (data['records'] as List).isNotEmpty) {
            rawList.addAll(data['records'] as List);
          } else if (data['list'] is List && (data['list'] as List).isNotEmpty) {
            rawList.addAll(data['list'] as List);
          } else if (data['categorized'] is Map) {
            final cat = data['categorized'] as Map;
            if (cat['pending'] is List) rawList.addAll(cat['pending'] as List);
          }
        }
      } else if (data is List) {
        backendChecked = true;
        rawList.addAll(data);
      }

      for (final item in rawList) {
        if (item is Map) {
          final rawStatus = (item['stage_status']?.toString().isNotEmpty == true)
              ? item['stage_status'].toString()
              : ((item['status_category']?.toString().isNotEmpty == true)
                  ? item['status_category'].toString()
                  : (item['status']?.toString() ?? ''));

          final statusUpper = rawStatus.trim().toUpperCase();
          final bool isPending = statusUpper.contains('PENDING') ||
              statusUpper.contains('WAITING') ||
              statusUpper.contains('PROCESS') ||
              statusUpper == 'REQUESTED' ||
              statusUpper == 'NEW';

          if (isPending) {
            foundPending = true;
            break;
          }
        }
      }

      // If backend was reachable, backend response is ground truth.
      // Only fallback to checking local storage if backend request failed / offline.
      if (!foundPending && !backendChecked) {
        final localList = LocalStorageRepositoryImpl().getSubmittedRecharges();
        final targetUserIdStr = userId.toString().replaceAll(RegExp(r'\D'), '');

        for (final item in localList) {
          if (item is Map) {
            final itemType = item['type']?.toString().toUpperCase() ?? '';
            final isWithdraw = itemType == 'WITHDRAW' ||
                item['isWithdraw'] == true ||
                (item['id']?.toString().contains('W') ?? false);
            if (!isWithdraw) continue;

            final itemUserIdStr = item['user_id']?.toString().replaceAll(RegExp(r'\D'), '') ??
                item['userId']?.toString().replaceAll(RegExp(r'\D'), '');

            if (targetUserIdStr.isNotEmpty &&
                itemUserIdStr != null &&
                itemUserIdStr.isNotEmpty &&
                itemUserIdStr != targetUserIdStr) {
              continue;
            }

            final statusUpper = (item['status']?.toString() ?? 'PENDING').toUpperCase();
            if (statusUpper.contains('PENDING') ||
                statusUpper.contains('WAITING') ||
                statusUpper.contains('PROCESS')) {
              foundPending = true;
              break;
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _hasPendingWithdrawal = foundPending;
        });
      }
      return foundPending;
    } catch (_) {
      return _hasPendingWithdrawal;
    }
  }

  Future<void> _submitForm() async {
    // 1. Re-verify pending withdrawal status first
    final bool isAlreadyPending = await _checkPendingWithdrawalStatus(silent: true);
    if (isAlreadyPending || _hasPendingWithdrawal) {
      if (mounted) {
        setState(() => _hasPendingWithdrawal = true);
      }
      return;
    }

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

      // Check if backend rejected due to existing pending request
      final String backendMsg = (data is Map<String, dynamic> && data['message'] != null)
          ? data['message'].toString()
          : '';
      final bool backendBlocked = backendMsg.toLowerCase().contains('already') ||
          backendMsg.toLowerCase().contains('pending') ||
          backendMsg.toLowerCase().contains('exist');

      if (backendBlocked) {
        if (mounted) {
          setState(() {
            _hasPendingWithdrawal = true;
            _isSubmitting = false;
          });
        }
        return;
      }

      if (data is Map<String, dynamic> && data['success'] == false) {
        if (mounted) {
          setState(() => _isSubmitting = false);
          _showIssueDialog(
            'Withdrawal Failed',
            backendMsg.isNotEmpty
                ? backendMsg
                : 'Failed to submit withdrawal request. Please check your inputs and try again.',
          );
        }
        return;
      }

      if (!mounted) return;

      final successMsg = backendMsg.isNotEmpty
          ? backendMsg
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
        _hasPendingWithdrawal = true;
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
        _hasPendingWithdrawal = true;
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

    try {
      await repo.saveSubmittedRecharge({
        'id': model.id,
        'bookName': model.bookName,
        'transactionDetails': 'Withdrawal • ${description.isNotEmpty ? description : model.description}',
        'amount': model.amount,
        'status': 'PENDING',
        'date': model.date,
        'user_id': userEmail,
        'type': 'WITHDRAW',
        'isWithdraw': true,
      });
    } catch (_) {}

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

  void _dismissSheetIfModal(BuildContext ctx) {
    if (!mounted) return;
    final route = ModalRoute.of(ctx);
    if (route is PopupRoute && Navigator.canPop(ctx)) {
      Navigator.of(ctx).pop();
    }
  }

  void _showSuccessDialog(String message, WithdrawRequestModel model, String agentId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(dialogContext).size.height * 0.88,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF090D1A)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFF10B981).withValues(alpha: 0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.3),
                  blurRadius: 28,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Compact Glowing Checkmark Icon
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF10B981).withValues(alpha: 0.2),
                          const Color(0xFF059669).withValues(alpha: 0.05),
                        ],
                      ),
                      border: Border.all(
                        color: const Color(0xFF10B981),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.45),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF10B981),
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Pill Badge: REQUEST RECEIVED
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'WITHDRAWAL REQUESTED ${model.id}',
                              style: GoogleFonts.outfit(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF10B981),
                                letterSpacing: 0.7,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    'Withdrawal Request Submitted!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Compact Summary Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131C33),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF1E293B),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Highlighted Amount Banner
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFF10B981).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Withdraw Amount',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFCBD5E1),
                                ),
                              ),
                              Text(
                                '₹${model.amount.toStringAsFixed(2)}',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildSummaryRow('Book Market', model.bookName, true),
                        const SizedBox(height: 6),
                        _buildSummaryRow('Status', 'Pending Agency Approval', true, statusColor: const Color(0xFFF59E0B)),
                        const SizedBox(height: 6),
                        _buildSummaryRow('Est. Processing', '5 - 15 Minutes', true, statusColor: const Color(0xFF00B2FF)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Primary Action Button: VIEW IN CHAT SCREEN
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (Navigator.canPop(dialogContext)) {
                          Navigator.of(dialogContext).pop(); // Close dialog safely
                        }
                        _dismissSheetIfModal(context); // Close parent bottom sheet ONLY if it's a modal sheet!
                        if (mounted) {
                          context.push('/chat/$agentId'); // Navigate to chat screen
                        }
                      },
                      icon: const Icon(Icons.chat_rounded, color: Colors.white, size: 17),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'VIEW IN CHAT SCREEN',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
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
                  const SizedBox(height: 8),

                  // Secondary Action Button: DONE
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: OutlinedButton(
                      onPressed: () {
                        if (Navigator.canPop(dialogContext)) {
                          Navigator.of(dialogContext).pop(); // Close dialog safely
                        }
                        _dismissSheetIfModal(context); // Close parent bottom sheet ONLY if it's a modal sheet!
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(
                          color: Color(0xFF334155),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'DONE',
                        style: TextStyle(
                          fontSize: 12,
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
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(dialogContext).size.height * 0.85,
            ),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
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
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
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
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
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
          color: const Color(0xFF061B2E),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Container(
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
                        Flexible(
                          child: Text(
                            'APPROVED PAYOUT ACCOUNT',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF10B981),
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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

            // QR Code / Passbook Image (Opened via compact VIEW QR CODE button)
            if (hasQrImage) ...[
              const SizedBox(height: 12),
              const Divider(height: 1, thickness: 0.8),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.qr_code_rounded, size: 16, color: Color(0xFF10B981)),
                      SizedBox(width: 6),
                      Text(
                        'Saved QR Code:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => _showImageDialog(acc.image!),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF10B981).withValues(alpha: 0.6),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.visibility_rounded, size: 14, color: Color(0xFF10B981)),
                          SizedBox(width: 5),
                          Text(
                            'VIEW QR CODE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF10B981),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
            ? const Color(0xFF1F1607)
            : const Color(0xFF1F0A0C),
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
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
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
                  padding: const EdgeInsets.symmetric(horizontal: 10),
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
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        isPending ? 'CHECK BANK STATUS IN PROFILE' : 'SAVE BANK DETAILS IN PROFILE',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 15),
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
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 300),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF10B981).withValues(alpha: 0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: 0.25),
                blurRadius: 20,
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF10B981), size: 18),
                      SizedBox(width: 6),
                      Text(
                        'SAVED PAYOUT QR CODE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF10B981),
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                    icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFF10B981), width: 1.5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: _buildAccountImageWidget(imgStr),
                ),
              ),
            ],
          ),
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
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF00B2FF),
              letterSpacing: 0.5,
            ),
          ),
          const TextSpan(
            text: ' *',
            style: TextStyle(
              fontSize: 12,
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
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: Color(0xFF00B2FF),
        letterSpacing: 0.5,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const isDark = true;
    const cardBg = Color(0xFF070D22);
    const inputBg = Color(0xFF050B1E);
    final borderColor = const Color(0xFF0066FF).withValues(alpha: 0.4);
    final hintColor = Colors.white.withValues(alpha: 0.4);
    const textColor = Colors.white;
    final maxHeight = MediaQuery.of(context).size.height * 0.88;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                    color: const Color(0xFF0066FF).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Top Row / Column: SELECT BOOK & WITHDRAW AMOUNT (Adaptive for all mobile sizes)
              LayoutBuilder(
                builder: (context, constraints) {
                  final bool isNarrow = constraints.maxWidth < 360;

                  Widget buildBookField() {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('SELECT BOOK', isDark),
                        const SizedBox(height: 6),
                        Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: inputBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor, width: 1.2),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedBook,
                              hint: Text(
                                _books.isEmpty
                                    ? 'No Book Account Available'
                                    : 'Select Book',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _books.isEmpty
                                      ? const Color(0xFFEF4444)
                                      : hintColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              isExpanded: true,
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Color(0xFF00B2FF),
                                size: 20,
                              ),
                              dropdownColor: const Color(0xFF050B1E),
                              style: const TextStyle(
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
                                    child: Text(
                                      book,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  Widget buildAmountField() {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('WITHDRAW AMOUNT', isDark),
                        const SizedBox(height: 6),
                        Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: inputBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor, width: 1.2),
                          ),
                          child: TextField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            cursorColor: const Color(0xFF00B2FF),
                            style: const TextStyle(
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
                              filled: false,
                              fillColor: Colors.transparent,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  if (isNarrow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildBookField(),
                        const SizedBox(height: 12),
                        buildAmountField(),
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: buildBookField()),
                      const SizedBox(width: 12),
                      Expanded(child: buildAmountField()),
                    ],
                  );
                },
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
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor, width: 1.2),
                ),
                child: TextField(
                  controller: _descriptionController,
                  maxLines: 2,
                  cursorColor: const Color(0xFF00B2FF),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Add optional remarks or notes for withdrawal...',
                    hintStyle: TextStyle(
                      fontSize: 12.5,
                      color: hintColor,
                      fontWeight: FontWeight.w400,
                    ),
                    filled: false,
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 5. Electric Blue Gradient Submit Button: "Withdraw Request ->" (Disabled when pending request exists)
              Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  gradient: _hasPendingWithdrawal
                      ? const LinearGradient(
                          colors: [Color(0xFF334155), Color(0xFF1E293B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : const LinearGradient(
                          colors: [Color(0xFF0077FF), Color(0xFF0044CE)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  boxShadow: [
                    BoxShadow(
                      color: (_hasPendingWithdrawal
                              ? const Color(0xFF1E293B)
                              : const Color(0xFF0066FF))
                          .withValues(alpha: 0.5),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: (_isSubmitting || _hasPendingWithdrawal) ? null : _submitForm,
                    borderRadius: BorderRadius.circular(26),
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
                              Flexible(
                                child: Text(
                                  _hasPendingWithdrawal ? 'Withdrawal Blocked' : 'Withdraw Request',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: _hasPendingWithdrawal ? const Color(0xFF94A3B8) : Colors.white,
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                _hasPendingWithdrawal ? Icons.lock_rounded : Icons.arrow_forward_rounded,
                                color: _hasPendingWithdrawal ? const Color(0xFF94A3B8) : Colors.white,
                                size: 18,
                              ),
                            ],
                          ),
                  ),
                ),
              ),

              // 6. Red Warning Pill Banner matching the design screenshot (below submit button)
              if (_hasPendingWithdrawal) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF280E14),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.8),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFEF4444),
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'You cannot request a withdrawal because a withdrawal request already exists!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFEF4444),
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
