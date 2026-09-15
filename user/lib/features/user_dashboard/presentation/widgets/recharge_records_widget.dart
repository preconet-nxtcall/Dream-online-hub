import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../models/user/recharge_record_model.dart';
import '../../../../network/api_client.dart';
import '../../../../storage/local_storage_repository.dart';
import '../../../../storage/secure_storage_service.dart';
import '../../../../widgets/skeleton_loader.dart';

class RechargeRecordsWidget extends StatefulWidget {
  final List<RechargeRecordModel>? initialRecords;
  final dynamic userId;
  final bool isCompactSingleLine;

  const RechargeRecordsWidget({
    super.key,
    this.initialRecords,
    this.userId,
    this.isCompactSingleLine = false,
  });

  @override
  State<RechargeRecordsWidget> createState() => RechargeRecordsWidgetState();
}

class RechargeRecordsWidgetState extends State<RechargeRecordsWidget> {
  String _selectedRecordType = 'RECHARGE'; // 'RECHARGE' or 'WITHDRAW'
  String _selectedStatusFilter = 'all'; // 'all', 'pending', 'successful', or 'rejected'
  String _searchQuery = '';
  int _pageSize = 15;
  int _currentPage = 1;
  final TextEditingController _searchController = TextEditingController();
  bool _isRefreshing = false;
  bool _isLoadingRecords = true;
  Timer? _autoRefreshTimer;

  List<RechargeRecordModel> _records = [];

  @override
  void initState() {
    super.initState();
    _records = List<RechargeRecordModel>.from(widget.initialRecords ?? []);
    _fetchBackendRecords();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted && !_isRefreshing) {
        _fetchBackendRecords(silent: true);
      }
    });
  }

  void addRecord(RechargeRecordModel record) {
    setState(() {
      _records.removeWhere((r) => r.id == record.id);
      _records.insert(0, record);
      _currentPage = 1;
    });
  }

  Future<void> refreshRecords() async {
    if (!mounted) return;
    setState(() => _isRefreshing = true);
    await _fetchBackendRecords();
    if (!mounted) return;
    setState(() => _isRefreshing = false);
  }

  String _formatDate(dynamic dateTsVal, dynamic fallbackDateVal) {
    if (dateTsVal != null && dateTsVal.toString().isNotEmpty) {
      final timestamp = int.tryParse(dateTsVal.toString());
      if (timestamp != null && timestamp > 0) {
        final dt = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000).toLocal();
        return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      }
    }
    return fallbackDateVal?.toString() ?? 'Recent';
  }

  Future<dynamic> _resolveUserId() async {
    if (widget.userId != null && widget.userId.toString().isNotEmpty) {
      final raw = widget.userId.toString().trim();
      final digitsOnly = raw.replaceAll(RegExp(r'\D'), '');
      return digitsOnly.isNotEmpty ? (int.tryParse(digitsOnly) ?? raw) : raw;
    }
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

  Future<void> _fetchBackendRecords({bool silent = false}) async {
    try {
      if (_records.isEmpty && !silent) {
        setState(() => _isLoadingRecords = true);
      }

      final apiClient = ApiClient();
      final userId = await _resolveUserId();

      final List<RechargeRecordModel> fetched = [];

      if (_selectedRecordType == 'RECHARGE') {
        final response = await apiClient.post(
          ApiEndpoints.getQrCode,
          options: Options(validateStatus: (status) => status != null && status < 500),
          data: {
            'action': 'recharge_records',
            'user_id': userId,
            'status_type': _selectedStatusFilter,
          },
        );

        if (!mounted) return;
        final data = response.data;
        List rawList = [];
        if (data is Map<String, dynamic>) {
          final isSuccess = data['success'] == true ||
              data['success'] == 1 ||
              data['success'] == '1' ||
              data['success'] == 'true';

          if (isSuccess || data['data'] != null || data['recharges'] != null || data['categorized'] != null) {
            if (data['data'] is List && (data['data'] as List).isNotEmpty) {
              rawList.addAll(data['data'] as List);
            } else if (data['recharges'] is List && (data['recharges'] as List).isNotEmpty) {
              rawList.addAll(data['recharges'] as List);
            } else if (data['records'] is List && (data['records'] as List).isNotEmpty) {
              rawList.addAll(data['records'] as List);
            } else if (data['list'] is List && (data['list'] as List).isNotEmpty) {
              rawList.addAll(data['list'] as List);
            } else if (data['categorized'] is Map) {
              final cat = data['categorized'] as Map;
              if (cat['pending'] is List) rawList.addAll(cat['pending'] as List);
              if (cat['successful'] is List) rawList.addAll(cat['successful'] as List);
              if (cat['rejected'] is List) rawList.addAll(cat['rejected'] as List);
            } else if (data['data'] is List) {
              rawList.addAll(data['data'] as List);
            }
          }
        } else if (data is List) {
          rawList.addAll(data);
        }

        for (final item in rawList) {
          final idVal = item['recharge_id'] ?? item['id'] ?? '';
          final idStr = idVal.toString();
          final bookIdVal = item['book_id']?.toString();
          final rawBookName = item['book_name']?.toString() ?? item['book']?.toString();

          String resolvedBookName = 'Lucky Vault';
          if (rawBookName != null && rawBookName.isNotEmpty) {
            resolvedBookName = rawBookName;
          } else if (bookIdVal != null) {
            switch (bookIdVal) {
              case '324': resolvedBookName = 'Lucky Vault'; break;
              case '323': resolvedBookName = 'Dice Verse'; break;
              case '322': resolvedBookName = 'Jackpot Spin'; break;
              case '321': resolvedBookName = 'Gold Rush Pro'; break;
              case '310': resolvedBookName = 'Infinity Fortune'; break;
              case '309': resolvedBookName = 'Crown Riches'; break;
            }
          }

          final rawTxn = item['transection_id'] ?? item['transaction_id'] ?? item['utr'] ?? '';
          final rawAmount = double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0;
          final rawStatus = item['stage_status']?.toString() ?? item['status']?.toString() ?? 'EMPLOYEE-PENDING';
          final formattedDate = item['formatted_date']?.toString() ??
              _formatDate(item['date_ts'] ?? item['created_at'], item['date']);
          final rawImageUrl = item['image_url']?.toString();
          final rawInvoiceUrl = item['invoice_url']?.toString();

          final rawUserName = item['user_name']?.toString() ??
              item['userName']?.toString() ??
              item['user']?.toString() ??
              item['name']?.toString() ??
              item['email']?.toString() ??
              (item['user_id'] != null ? 'User ${item['user_id']}' : null);

          fetched.add(
            RechargeRecordModel(
              id: idStr.startsWith('#') ? idStr : '#$idStr',
              bookName: resolvedBookName,
              transactionDetails: 'Txn: $rawTxn • ₹${rawAmount.toStringAsFixed(2)}',
              amount: rawAmount,
              status: rawStatus,
              date: formattedDate,
              imageUrl: rawImageUrl,
              invoiceUrl: rawInvoiceUrl,
              userName: rawUserName,
            ),
          );
        }

        // Also merge local submitted recharges so newly created recharges show instantly
        final localList = LocalStorageRepositoryImpl().getSubmittedRecharges();
        for (final item in localList) {
          if (item is Map) {
            final idStr = item['id']?.toString() ?? '';
            final formattedId = idStr.startsWith('#') ? idStr : '#$idStr';
            if (idStr.isNotEmpty && !fetched.any((r) => r.id == formattedId)) {
              fetched.insert(
                0,
                RechargeRecordModel(
                  id: formattedId,
                  bookName: item['bookName']?.toString() ?? 'Lucky Vault',
                  transactionDetails: item['transactionDetails']?.toString() ?? '',
                  amount: double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0,
                  status: item['status']?.toString() ?? 'EMPLOYEE-PENDING',
                  date: item['date']?.toString() ?? 'Just now',
                  imageUrl: item['imageUrl']?.toString() ?? item['image_url']?.toString(),
                  invoiceUrl: item['invoiceUrl']?.toString() ?? item['invoice_url']?.toString(),
                ),
              );
            }
          }
        }
      } else {
        // Fetch Withdraw Records (action: withdraw_records, status_type: _selectedStatusFilter)
        final withdrawResponse = await apiClient.post(
          ApiEndpoints.getQrCode,
          options: Options(validateStatus: (status) => status != null && status < 500),
          data: {
            'action': 'withdraw_records',
            'user_id': userId,
            'status_type': _selectedStatusFilter,
          },
        );

        if (!mounted) return;
        List rawWithdrawList = [];
        final wData = withdrawResponse.data;
        if (wData is Map<String, dynamic>) {
          final isSuccess = wData['success'] == true ||
              wData['success'] == 1 ||
              wData['success'] == '1' ||
              wData['success'] == 'true';

          if (isSuccess || wData['data'] != null || wData['withdrawals'] != null || wData['categorized'] != null) {
            if (wData['data'] is List && (wData['data'] as List).isNotEmpty) {
              rawWithdrawList.addAll(wData['data'] as List);
            } else if (wData['withdrawals'] is List && (wData['withdrawals'] as List).isNotEmpty) {
              rawWithdrawList.addAll(wData['withdrawals'] as List);
            } else if (wData['records'] is List && (wData['records'] as List).isNotEmpty) {
              rawWithdrawList.addAll(wData['records'] as List);
            } else if (wData['list'] is List && (wData['list'] as List).isNotEmpty) {
              rawWithdrawList.addAll(wData['list'] as List);
            } else if (wData['categorized'] is Map) {
              final cat = wData['categorized'] as Map;
              if (cat['pending'] is List) rawWithdrawList.addAll(cat['pending'] as List);
              if (cat['successful'] is List) rawWithdrawList.addAll(cat['successful'] as List);
              if (cat['rejected'] is List) rawWithdrawList.addAll(cat['rejected'] as List);
            } else if (wData['data'] is List) {
              rawWithdrawList.addAll(wData['data'] as List);
            }
          }
        } else if (wData is List) {
          rawWithdrawList.addAll(wData);
        }

        for (final item in rawWithdrawList) {
          final wId = item['withdrawal_id'] ?? item['id'] ?? '';
          final wIdStr = wId.toString();
          final rawAmount = double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0;

          final rawStatus = (item['stage_status']?.toString().isNotEmpty == true)
              ? item['stage_status'].toString()
              : ((item['status_category']?.toString().isNotEmpty == true)
                  ? item['status_category'].toString()
                  : (item['status']?.toString() ?? 'PENDING'));

          final rawBookName = item['book_name']?.toString() ?? item['book']?.toString() ?? 'Lucky Vault';

          final rawDetail = (item['deatil']?.toString().trim().isNotEmpty == true)
              ? item['deatil'].toString().trim()
              : ((item['detail']?.toString().trim().isNotEmpty == true)
                  ? item['detail'].toString().trim()
                  : ((item['description']?.toString().trim().isNotEmpty == true)
                      ? item['description'].toString().trim()
                      : ((item['remark']?.toString().trim().isNotEmpty == true)
                          ? item['remark'].toString().trim()
                          : 'Withdrawal Request')));

          final formattedDate = item['formatted_date']?.toString() ??
              _formatDate(item['date_ts'] ?? item['created_at'], item['date']);
          final rawWUserName = item['user_name']?.toString() ??
              item['userName']?.toString() ??
              item['user']?.toString() ??
              item['name']?.toString() ??
              item['email']?.toString() ??
              (item['user_id'] != null ? 'User ${item['user_id']}' : null);

          final rawImageUrl = (item['emp_agency_image_url']?.toString().trim().isNotEmpty == true)
              ? item['emp_agency_image_url'].toString().trim()
              : ((item['image_url']?.toString().trim().isNotEmpty == true)
                  ? item['image_url'].toString().trim()
                  : (item['image']?.toString() ?? item['emp_agency_image']?.toString()));

          fetched.add(
            RechargeRecordModel(
              id: wIdStr.startsWith('#') ? wIdStr : '#W$wIdStr',
              bookName: rawBookName,
              transactionDetails: 'Withdrawal • $rawDetail',
              amount: rawAmount,
              status: rawStatus,
              date: formattedDate,
              imageUrl: rawImageUrl,
              userName: rawWUserName,
            ),
          );
        }
      }

      if (mounted) {
        setState(() {
          _records = fetched;
        });
      }
    } catch (_) {
      if (mounted) {
        _loadLocalSubmittedRecords();
      }
    } finally {
      if (mounted && !silent) {
        setState(() => _isLoadingRecords = false);
      }
    }
  }

  // ignore: unused_element
  Future<void> _downloadOrOpenInvoice(BuildContext context, String url) async {
    try {
      final fileName = url.split('/').last;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text('Opening invoice ($fileName)...')),
            ],
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFF0F172A),
          behavior: SnackBarBehavior.floating,
        ),
      );

      final uri = Uri.parse(url);
      bool launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
      }

      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to open invoice link: $url'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not download invoice: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _loadLocalSubmittedRecords() {
    final localList = LocalStorageRepositoryImpl().getSubmittedRecharges();
    final List<RechargeRecordModel> localRecords = [];

    final targetUserIdStr = widget.userId?.toString().replaceAll(RegExp(r'\D'), '');

    for (final item in localList) {
      if (item is Map) {
        final itemUserIdStr = item['user_id']?.toString().replaceAll(RegExp(r'\D'), '') ??
            item['userId']?.toString().replaceAll(RegExp(r'\D'), '');

        if (targetUserIdStr != null &&
            targetUserIdStr.isNotEmpty &&
            itemUserIdStr != null &&
            itemUserIdStr.isNotEmpty &&
            itemUserIdStr != targetUserIdStr) {
          continue; // Skip records belonging to another user
        }

        final idStr = item['id']?.toString() ?? '#01';
        localRecords.add(
          RechargeRecordModel(
            id: idStr.startsWith('#') ? idStr : '#$idStr',
            bookName: item['bookName']?.toString() ?? 'Lucky Vault',
            transactionDetails: item['transactionDetails']?.toString() ?? '',
            amount: double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0,
            status: item['status']?.toString() ?? 'EMPLOYEE-PENDING',
            date: item['date']?.toString() ?? 'Just now',
            imageUrl: item['imageUrl']?.toString() ?? item['image_url']?.toString(),
            invoiceUrl: item['invoiceUrl']?.toString() ?? item['invoice_url']?.toString(),
          ),
        );
      } else if (item is RechargeRecordModel) {
        localRecords.add(item);
      }
    }

    if (mounted) {
      setState(() {
        _records = localRecords;
      });
    }
  }

  @override
  void didUpdateWidget(covariant RechargeRecordsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialRecords != oldWidget.initialRecords || widget.userId != oldWidget.userId) {
      setState(() {
        _records = List<RechargeRecordModel>.from(widget.initialRecords ?? []);
        _currentPage = 1;
      });
      _fetchBackendRecords();
    }
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  List<RechargeRecordModel> get _filteredRecords {
    final query = _searchQuery.trim().toLowerCase();
    final filter = _selectedStatusFilter.trim().toLowerCase();

    return _records.where((rec) {
      final status = (rec.status).toLowerCase();
      final isPending = status.contains('pending') || status.contains('process') || status.contains('wait');
      final isSuccessful = status.contains('done') ||
          status.contains('successful') ||
          status.contains('success') ||
          status.contains('approved') ||
          status.contains('complete') ||
          status.contains('accept') ||
          status.contains('finish');
      final isRejected = status.contains('reject') ||
          status.contains('failed') ||
          status.contains('declined') ||
          status.contains('cancel');

      bool matchesStatus = false;
      if (filter == 'pending') {
        matchesStatus = isPending;
      } else if (filter == 'successful') {
        matchesStatus = isSuccessful;
      } else if (filter == 'rejected') {
        matchesStatus = isRejected;
      } else {
        matchesStatus = true;
      }

      if (!matchesStatus) return false;
      if (query.isEmpty) return true;

      final book = (rec.bookName).toLowerCase();
      final details = (rec.transactionDetails).toLowerCase();
      final id = (rec.id).toLowerCase();

      return book.contains(query) || details.contains(query) || id.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isCompactSingleLine ? Theme.of(context).brightness == Brightness.dark : true;

    final filtered = _filteredRecords;
    final totalRecords = filtered.length;
    final totalPages = (totalRecords / _pageSize).ceil();

    if (_currentPage > totalPages && totalPages > 0) {
      _currentPage = totalPages;
    } else if (_currentPage < 1) {
      _currentPage = 1;
    }

    final startIndex = (_currentPage - 1) * _pageSize;
    final endIndex = (startIndex + _pageSize < totalRecords) ? startIndex + _pageSize : totalRecords;
    final displayedRecords = (startIndex < totalRecords) ? filtered.sublist(startIndex, endIndex) : <RechargeRecordModel>[];

    return Container(
      decoration: widget.isCompactSingleLine
          ? null
          : BoxDecoration(
              color: isDark ? const Color(0xFF070D22) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF0066FF).withValues(alpha: 0.4)
                    : const Color(0xFFE2E8F0),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0066FF).withValues(alpha: isDark ? 0.15 : 0.05),
                  blurRadius: 20,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!widget.isCompactSingleLine) ...[
            // 1. Header: Icon, Dynamic Title ("Recharge Records" / "Withdrawal Records") & Sync Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _selectedRecordType == 'RECHARGE'
                            ? const [Color(0xFFFF6B00), Color(0xFFF59E0B)]
                            : const [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: (_selectedRecordType == 'RECHARGE'
                                  ? const Color(0xFFF97316)
                                  : const Color(0xFF8B5CF6))
                              .withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      _selectedRecordType == 'RECHARGE'
                          ? Icons.flash_on_rounded
                          : Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedRecordType == 'RECHARGE' ? 'Recharge Records' : 'Withdrawal Records',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: _isRefreshing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF00B2FF),
                            ),
                          )
                        : const Icon(
                            Icons.refresh_rounded,
                            color: Color(0xFF00B2FF),
                            size: 22,
                          ),
                    tooltip: 'Sync Database Records',
                    onPressed: _isRefreshing ? null : refreshRecords,
                  ),
                ],
              ),
            ),

            // 2. Record Type Chips Row (Recharge vs Withdraw)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTypePill(
                      label: 'Recharge',
                      icon: Icons.flash_on_rounded,
                      typeValue: 'RECHARGE',
                      isSelected: _selectedRecordType == 'RECHARGE',
                      activeGradient: const LinearGradient(
                        colors: [Color(0xFFFF6B00), Color(0xFFF59E0B)],
                      ),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTypePill(
                      label: 'Withdraw',
                      icon: Icons.account_balance_wallet_rounded,
                      typeValue: 'WITHDRAW',
                      isSelected: _selectedRecordType == 'WITHDRAW',
                      activeGradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                      ),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 2. Status Tabs Row: All, Pending, Successful & Rejected
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // All Tab Pill
                  _buildStatusPill(
                    label: 'All',
                    icon: Icons.grid_view_rounded,
                    statusValue: 'all',
                    isSelected: _selectedStatusFilter == 'all',
                    activeBg: const Color(0xFF0A1E3F),
                    activeFg: const Color(0xFF00B2FF),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),

                  // Pending Tab Pill
                  _buildStatusPill(
                    label: 'Pending',
                    icon: Icons.access_time_rounded,
                    statusValue: 'pending',
                    isSelected: _selectedStatusFilter == 'pending',
                    activeBg: const Color(0xFF2E2105),
                    activeFg: const Color(0xFFFFB800),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),

                  // Successful Tab Pill
                  _buildStatusPill(
                    label: 'Successful',
                    icon: Icons.check_circle_outline_rounded,
                    statusValue: 'successful',
                    isSelected: _selectedStatusFilter == 'successful',
                    activeBg: const Color(0xFF052E16),
                    activeFg: const Color(0xFF10B981),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),

                  // Rejected Tab Pill
                  _buildStatusPill(
                    label: 'Rejected',
                    icon: Icons.cancel_outlined,
                    statusValue: 'rejected',
                    isSelected: _selectedStatusFilter == 'rejected',
                    activeBg: const Color(0xFF2E080A),
                    activeFg: const Color(0xFFEF4444),
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (!widget.isCompactSingleLine) ...[
            const Divider(height: 1, thickness: 0.8),
            const SizedBox(height: 16),

            // 3. Search & Showing Dropdown Controls (Adaptive Layout)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bool isNarrow = constraints.maxWidth < 360;

                  Widget buildSearchInput() {
                    return Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF050B1E) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xFF0066FF).withValues(alpha: 0.4) : const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                            _currentPage = 1;
                          });
                        },
                        style: TextStyle(
                          fontSize: 13.5,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          hintStyle: TextStyle(
                            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                            fontSize: 13.5,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            size: 18,
                            color: Color(0xFF00B2FF),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    );
                  }

                  Widget buildShowingDropdown() {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Showing',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          height: 38,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF050B1E) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark ? const Color(0xFF0066FF).withValues(alpha: 0.4) : const Color(0xFFCBD5E1),
                              width: 1,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _pageSize,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF00B2FF)),
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              dropdownColor: isDark ? const Color(0xFF070D22) : Colors.white,
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _pageSize = val;
                                    _currentPage = 1;
                                  });
                                }
                              },
                              items: [
                                for (final size in [5, 10, 15, 25, 50])
                                  DropdownMenuItem<int>(
                                    value: size,
                                    child: Text('$size'),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  if (isNarrow) {
                    return Column(
                      children: [
                        buildSearchInput(),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: buildShowingDropdown(),
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: buildSearchInput()),
                      const SizedBox(width: 16),
                      buildShowingDropdown(),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // 4. Table Header Row
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0A122E) : const Color(0xFFFAF7F2),
                border: Border.symmetric(
                  horizontal: BorderSide(
                    color: isDark ? const Color(0xFF0066FF).withValues(alpha: 0.25) : const Color(0xFFF1EFE9),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      '# / BOOK NAME',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: isDark ? const Color(0xFF00B2FF) : const Color(0xFF475569),
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text(
                      'TRANSACTION DETAILS',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: isDark ? const Color(0xFF00B2FF) : const Color(0xFF475569),
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'STATUS & DATE',
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: isDark ? const Color(0xFF00B2FF) : const Color(0xFF475569),
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 5. Shimmer Skeleton Loading / Empty State / Table Rows
          if (_isLoadingRecords)
            const RechargeRecordSkeletonLoader(count: 4)
          else if (displayedRecords.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 20),
              child: Center(
                child: Text(
                  'No records found',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF64748B),
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayedRecords.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                thickness: 0.8,
                color: isDark ? const Color(0xFF0066FF).withValues(alpha: 0.15) : const Color(0xFFF1F5F9),
              ),
              itemBuilder: (ctx, index) {
                final item = displayedRecords[index];

                if (widget.isCompactSingleLine) {
                  final statusLower = item.status.toLowerCase();
                  final isDone = statusLower.contains('done') ||
                      statusLower.contains('successful') ||
                      statusLower.contains('approved');
                  final isReject = statusLower.contains('reject') ||
                      statusLower.contains('failed') ||
                      statusLower.contains('declined');

                  String displayLabel = 'Pending';
                  Color badgeFg = const Color(0xFFF59E0B);
                  if (isDone) {
                    displayLabel = 'Approved';
                    badgeFg = const Color(0xFF10B981);
                  } else if (isReject) {
                    displayLabel = 'Rejected';
                    badgeFg = const Color(0xFFEF4444);
                  }

                  final clientName = item.userName?.isNotEmpty == true
                      ? item.userName!
                      : 'User ${index + 1}';
                  final amountStr = '₹${item.amount.toStringAsFixed(0)}';

                  String notificationText = '';
                  if (_selectedRecordType == 'RECHARGE') {
                    if (isDone) {
                      notificationText = '$clientName recharge $amountStr approved on ${item.bookName}';
                    } else if (isReject) {
                      notificationText = '$clientName recharge $amountStr rejected on ${item.bookName}';
                    } else {
                      notificationText = '$clientName requested $amountStr recharge on ${item.bookName}';
                    }
                  } else {
                    if (isDone) {
                      notificationText = '$clientName withdrawal $amountStr approved on ${item.bookName}';
                    } else if (isReject) {
                      notificationText = '$clientName withdrawal $amountStr rejected on ${item.bookName}';
                    } else {
                      notificationText = '$clientName requested $amountStr withdrawal on ${item.bookName}';
                    }
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF13102B) : const Color(0xFFF8F7FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? const Color(0xFF2E2756) : const Color(0xFFECEAFE),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _selectedRecordType == 'RECHARGE' ? Icons.flash_on_rounded : Icons.account_balance_wallet_rounded,
                          color: badgeFg,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        // Single Line Notification Format
                        Expanded(
                          child: Text(
                            notificationText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Single Line Status Pill Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: badgeFg.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            displayLabel,
                            style: TextStyle(
                              color: badgeFg,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      // # / Book Name
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.id,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xFF00B2FF) : const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.bookName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Transaction Details
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '₹${item.amount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF10B981),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.transactionDetails,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Status & Date
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Builder(
                              builder: (context) {
                                final statusLower = item.status.toLowerCase();
                                final isDone = statusLower.contains('done') ||
                                    statusLower.contains('successful') ||
                                    statusLower.contains('approved');
                                final isReject = statusLower.contains('reject') ||
                                    statusLower.contains('failed') ||
                                    statusLower.contains('declined');

                                String displayLabel = 'PENDING';
                                Color badgeFg = const Color(0xFFD97706);
                                Color badgeBg = const Color(0xFFFFF7ED);

                                if (isDone) {
                                  displayLabel = 'SUCCESSFUL';
                                  badgeFg = const Color(0xFF10B981);
                                  badgeBg = isDark ? const Color(0xFF14382B) : const Color(0xFFE6F7ED);
                                } else if (isReject) {
                                  displayLabel = 'REJECTED';
                                  badgeFg = const Color(0xFFEF4444);
                                  badgeBg = isDark ? const Color(0xFF381418) : const Color(0xFFFEE2E2);
                                } else {
                                  displayLabel = 'PENDING';
                                  badgeFg = const Color(0xFFFFB800);
                                  badgeBg = isDark ? const Color(0xFF332A15) : const Color(0xFFFFF7ED);
                                }

                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: badgeBg,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      displayLabel,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: badgeFg,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.date,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                              ),
                            ),
                            // Invoice PDF button commented out for future use
                            /*
                            if (item.invoiceUrl != null && item.invoiceUrl!.isNotEmpty) ...[
                              const SizedBox(height: 5),
                              GestureDetector(
                                onTap: () => _downloadOrOpenInvoice(context, item.invoiceUrl!),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(0xFF38BDF8).withValues(alpha: 0.5),
                                      width: 1,
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.picture_as_pdf_rounded, size: 12, color: Color(0xFF38BDF8)),
                                      SizedBox(width: 4),
                                      Text(
                                        'Invoice PDF',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF38BDF8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            */
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

          // 6. Interactive Pagination Footer
          _buildPaginationFooter(totalRecords, totalPages, isDark),
        ],
      ),
    );
  }

  Widget _buildPaginationFooter(int totalRecords, int totalPages, bool isDark) {
    if (totalRecords == 0 || totalPages <= 1) {
      return const SizedBox.shrink();
    }

    final startRecord = (_currentPage - 1) * _pageSize + 1;
    final endRecord = (_currentPage * _pageSize > totalRecords)
        ? totalRecords
        : _currentPage * _pageSize;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF070D22) : const Color(0xFFFAF8F5),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF0066FF).withValues(alpha: 0.25) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isNarrow = constraints.maxWidth < 360;

          Widget buildCounterText() {
            return Text(
              'Showing $startRecord-$endRecord of $totalRecords',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            );
          }

          Widget buildPageControls() {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Previous Page Button
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, size: 20),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                  color: _currentPage > 1
                      ? const Color(0xFFF97316)
                      : (isDark ? Colors.white24 : Colors.black26),
                  onPressed: _currentPage > 1
                      ? () => setState(() => _currentPage--)
                      : null,
                ),
                const SizedBox(width: 2),

                // Page Number Buttons
                for (int p = 1; p <= totalPages; p++)
                  if (p == 1 ||
                      p == totalPages ||
                      (p >= _currentPage - 1 && p <= _currentPage + 1))
                    GestureDetector(
                      onTap: () => setState(() => _currentPage = p),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _currentPage == p
                              ? const Color(0xFF0066FF)
                              : (isDark ? const Color(0xFF050B1E) : const Color(0xFFE2E8F0)),
                          borderRadius: BorderRadius.circular(8),
                          border: _currentPage == p
                              ? null
                              : Border.all(
                                  color: isDark
                                      ? const Color(0xFF0066FF).withValues(alpha: 0.3)
                                      : Colors.transparent,
                                ),
                        ),
                        child: Text(
                          '$p',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: _currentPage == p
                                ? Colors.white
                                : (isDark ? Colors.white70 : const Color(0xFF475569)),
                          ),
                        ),
                      ),
                    ),

                const SizedBox(width: 2),
                // Next Page Button
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, size: 20),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                  color: _currentPage < totalPages
                      ? const Color(0xFFF97316)
                      : (isDark ? Colors.white24 : Colors.black26),
                  onPressed: _currentPage < totalPages
                      ? () => setState(() => _currentPage++)
                      : null,
                ),
              ],
            );
          }

          if (isNarrow) {
            return Column(
              children: [
                buildCounterText(),
                const SizedBox(height: 8),
                buildPageControls(),
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              buildCounterText(),
              buildPageControls(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTypePill({
    required String label,
    required IconData icon,
    required String typeValue,
    required bool isSelected,
    required Gradient activeGradient,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (_selectedRecordType != typeValue) {
            setState(() {
              _selectedRecordType = typeValue;
              _currentPage = 1;
              _records = [];
            });
            _fetchBackendRecords();
          }
        },
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            gradient: isSelected ? activeGradient : null,
            color: isSelected
                ? null
                : (isDark ? const Color(0xFF050B1E) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : (isDark ? const Color(0xFF0066FF).withValues(alpha: 0.3) : const Color(0xFFE2E8F0)),
              width: 1.2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: (typeValue == 'RECHARGE'
                              ? const Color(0xFFF97316)
                              : const Color(0xFF8B5CF6))
                          .withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 17,
                color: isSelected
                    ? Colors.white
                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPill({
    required String label,
    required IconData icon,
    required String statusValue,
    required bool isSelected,
    required Color activeBg,
    required Color activeFg,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStatusFilter = statusValue;
          _currentPage = 1;
        });
        _fetchBackendRecords();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : (isDark ? const Color(0xFF050B1E) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? activeFg.withValues(alpha: 0.6)
                : (isDark ? const Color(0xFF0066FF).withValues(alpha: 0.25) : const Color(0xFFE2E8F0)),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? activeFg : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? activeFg : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmering table row skeleton loader widget for Recharge Records
class RechargeRecordSkeletonLoader extends StatelessWidget {
  final int count;
  const RechargeRecordSkeletonLoader({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        count,
        (index) => const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // # / Book Name skeleton
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 30, height: 10, borderRadius: 4),
                    SizedBox(height: 6),
                    ShimmerBox(width: 90, height: 14, borderRadius: 4),
                  ],
                ),
              ),

              // Amount & Txn Details skeleton
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 60, height: 14, borderRadius: 4),
                    SizedBox(height: 6),
                    ShimmerBox(width: 120, height: 12, borderRadius: 4),
                  ],
                ),
              ),

              // Status Pill & Date skeleton
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ShimmerBox(width: 75, height: 18, borderRadius: 8),
                    SizedBox(height: 6),
                    ShimmerBox(width: 55, height: 10, borderRadius: 4),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
