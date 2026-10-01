import 'package:flutter/material.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../models/user/recharge_record_model.dart';
import '../../../../network/api_client.dart';
import '../../../../storage/local_storage_repository.dart';
import '../../../../storage/secure_storage_service.dart';
import '../../../../widgets/skeleton_loader.dart';

class WithdrawalRequestsWidget extends StatefulWidget {
  final int? userId;
  final List<RechargeRecordModel>? initialRecords;

  const WithdrawalRequestsWidget({
    super.key,
    this.userId,
    this.initialRecords,
  });

  @override
  State<WithdrawalRequestsWidget> createState() => WithdrawalRequestsWidgetState();
}

class WithdrawalRequestsWidgetState extends State<WithdrawalRequestsWidget> {
  List<RechargeRecordModel> _records = [];
  bool _isLoading = false;
  String _selectedStatusFilter = 'all'; // 'all', 'pending', 'successful', 'rejected'
  String _searchQuery = '';
  int _currentPage = 1;
  int _pageSize = 10;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialRecords != null && widget.initialRecords!.isNotEmpty) {
      _records = List.from(widget.initialRecords!);
    } else {
      _fetchBackendWithdrawals();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> refreshRecords() async {
    await _fetchBackendWithdrawals();
  }

  Future<String> _resolveCurrentAgencyId() async {
    if (widget.userId != null && widget.userId.toString().isNotEmpty) {
      final digitsOnly = widget.userId.toString().replaceAll(RegExp(r'\D'), '');
      if (digitsOnly.isNotEmpty) return digitsOnly;
    }
    final currentUser = LocalStorageRepositoryImpl().getUser();
    if (currentUser?.id != null && currentUser!.id.isNotEmpty) {
      final digitsOnly = currentUser.id.replaceAll(RegExp(r'\D'), '');
      if (digitsOnly.isNotEmpty) return digitsOnly;
    }
    final storedUserId = await SecureStorageService().read(StorageKeys.userId);
    if (storedUserId != null && storedUserId.isNotEmpty) {
      final digitsOnly = storedUserId.replaceAll(RegExp(r'\D'), '');
      if (digitsOnly.isNotEmpty) return digitsOnly;
    }
    return '';
  }

  Future<void> _fetchBackendWithdrawals() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final apiClient = ApiClient();
      final currentAgencyId = await _resolveCurrentAgencyId();

      final response = await apiClient.post(
        ApiEndpoints.getQrCode,
        data: {
          'action': 'withdraw_records',
          'status_type': 'all',
        },
      );

      final List<RechargeRecordModel> fetchedList = [];
      final data = response.data;
      if (data is Map<String, dynamic> &&
          (data['status'] == 'success' || data['success'] == true || data['data'] != null || data['withdrawals'] != null)) {
        final List listData = [];
        final rawData = data['data'] ?? data['withdrawals'];

        if (rawData is List) {
          listData.addAll(rawData);
        } else if (rawData is Map<String, dynamic>) {
          if (rawData['pending'] is List) listData.addAll(rawData['pending'] as List);
          if (rawData['successful'] is List) listData.addAll(rawData['successful'] as List);
          if (rawData['rejected'] is List) listData.addAll(rawData['rejected'] as List);
        }

        for (final item in listData) {
          if (item is Map<String, dynamic>) {
            // Strict Agency Isolation: WHERE agency_id = '$app_u_id'
            if (currentAgencyId.isNotEmpty) {
              final itemEmpId = (item['agency_id'] ?? item['emp_id'])?.toString().replaceAll(RegExp(r'\D'), '');
              if (itemEmpId != null && itemEmpId.isNotEmpty && itemEmpId != currentAgencyId && currentAgencyId != '1') {
                continue;
              }
            }

            final idStr = item['withdrawal_id']?.toString() ?? item['id']?.toString() ?? '#01';
            final formattedId = idStr.startsWith('#') ? idStr : '#$idStr';
            final amountVal = double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0;
            final stageStatus = item['stage_status']?.toString() ?? 'EMPLOYEE-PENDING';
            final bookName = item['book_name']?.toString() ?? 'Lucky Vault';
            final userName = item['user_name']?.toString() ?? item['name']?.toString() ?? 'Client';
            final formattedDate = item['formatted_date']?.toString() ?? item['date']?.toString() ?? 'Just now';

            // User Payment details
            final acHolder = item['user_ac_holder_name']?.toString() ?? '';
            final acNo = item['user_ac_number']?.toString() ?? '';
            final bankName = item['user_bank_name']?.toString() ?? '';
            final ifsc = item['user_bank_ifsc']?.toString() ?? '';
            final upi = item['user_upi_id']?.toString() ?? '';

            final detailSummary = [
              if (acHolder.isNotEmpty) 'A/C: $acHolder',
              if (acNo.isNotEmpty) 'No: $acNo',
              if (bankName.isNotEmpty) 'Bank: $bankName',
              if (ifsc.isNotEmpty) 'IFSC: $ifsc',
              if (upi.isNotEmpty) 'UPI: $upi',
            ].join(' | ');

            fetchedList.add(
              RechargeRecordModel(
                id: formattedId,
                bookName: bookName,
                userName: userName,
                transactionDetails: detailSummary.isNotEmpty ? detailSummary : (item['deatil']?.toString() ?? item['transaction_id']?.toString() ?? 'Withdrawal Request'),
                amount: amountVal,
                status: stageStatus,
                date: formattedDate,
                imageUrl: item['image_url']?.toString() ?? item['image']?.toString(),
                invoiceUrl: item['emp_agency_image_url']?.toString() ?? item['emp_agency_image']?.toString(),
              ),
            );
          }
        }
      }

      if (mounted) {
        setState(() {
          _records = fetchedList;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ─── View Withdrawal Details Modal ───────────────────────────────────────
  void _showViewDetailsModal(BuildContext context, RechargeRecordModel item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF14102B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Color(0xFFF59E0B),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Check Withdrawal Details',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(modalContext),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1838) : const Color(0xFFF8F7FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2E2756) : const Color(0xFFECEAFE),
                  ),
                ),
                child: Column(
                  children: [
                    if (item.userName != null && item.userName!.isNotEmpty) ...[
                      _buildModalDetailRow('Player / Client', item.userName!, isDark),
                      const Divider(height: 16),
                    ],
                    _buildModalDetailRow('Book Platform', item.bookName, isDark),
                    const Divider(height: 16),
                    _buildModalDetailRow('Withdrawal ID', item.id, isDark),
                    const Divider(height: 16),
                    _buildModalDetailRow('Withdraw Amount', '₹${item.amount.toStringAsFixed(2)}', isDark, isHighlight: true),
                    const Divider(height: 16),
                    _buildModalDetailRow('Payment Details', item.transactionDetails, isDark),
                    const Divider(height: 16),
                    _buildModalDetailRow('Date & Time', item.date, isDark),
                    const Divider(height: 16),
                    _buildModalDetailRow('Stage Status', item.status.toUpperCase(), isDark),
                    Builder(
                      builder: (context) {
                        final stUpper = item.status.toUpperCase();
                        final isAlreadyProcessed = stUpper.contains('AGENCY-DONE') ||
                            stUpper.contains('AGENCY-REJECT') ||
                            stUpper.contains('EMPLOYEE-DONE') ||
                            stUpper.contains('EMPLOYEE-REJECT') ||
                            stUpper.contains('DONE') ||
                            stUpper.contains('SUCCESSFUL') ||
                            stUpper.contains('REJECTED');
                        if (isAlreadyProcessed) {
                          return Column(
                            children: [
                              const Divider(height: 16),
                              _buildModalDetailRow('Verification Lock', 'Verified & Locked (One-Time Action Completed)', isDark, isHighlight: true),
                            ],
                          );
                        } else if (stUpper.contains('EMPLOYEE-PENDING') || stUpper.contains('EMPLOYEE-PASS') || stUpper.contains('AGENCY-PENDING')) {
                          return Column(
                            children: [
                              const Divider(height: 16),
                              _buildModalDetailRow('Authority Status', 'Authority Not Verified Yet.', isDark, isRed: true),
                            ],
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),
              if (item.imageUrl != null && item.imageUrl!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(
                      Icons.image_outlined,
                      size: 16,
                      color: Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'User QR / Bank Passbook Image:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isDark ? const Color(0xFF2E2756) : const Color(0xFFE2E8F0),
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Image.network(
                      item.imageUrl!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 80,
                        color: isDark ? const Color(0xFF1E1B2E) : const Color(0xFFF1F5F9),
                        child: Center(
                          child: Text(
                            'Image not available',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Builder(
                builder: (context) {
                  final stUpper = item.status.toUpperCase();
                  final isAlreadyApprovedOrProcessed = stUpper.contains('AGENCY-DONE') ||
                      stUpper.contains('AGENCY-REJECT') ||
                      stUpper.contains('EMPLOYEE-DONE') ||
                      stUpper.contains('EMPLOYEE-REJECT') ||
                      stUpper.contains('DONE') ||
                      stUpper.contains('SUCCESSFUL') ||
                      stUpper.contains('REJECTED');

                  final canProcess = !isAlreadyApprovedOrProcessed &&
                      (stUpper.contains('AGENCY-PENDING') || stUpper == 'PENDING' || stUpper.contains('EMPLOYEE-PASS'));

                  return Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(modalContext),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: isDark ? const Color(0xFF332D4A) : const Color(0xFFCBD5E1),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              'CLOSE',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white70 : const Color(0xFF475569),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (canProcess) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 46,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(modalContext);
                                _showProcessWithdrawalModal(context, item);
                              },
                              icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                              label: const Text(
                                'PROCESS WITHDRAWAL',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF59E0B),
                                elevation: 2,
                                shadowColor: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Process / Verify Withdrawal Modal ────────────────────────────────────
  void _showProcessWithdrawalModal(BuildContext context, RechargeRecordModel item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String selectedStatus = 'AGENCY-DONE';
    final transactionIdController = TextEditingController();
    final remarkController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF14102B) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Process Withdrawal (Agency)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Record ${item.id} • ₹${item.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFF59E0B),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'CHOOSE ACTION',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF221F3D) : const Color(0xFFF8F7FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? const Color(0xFF332D4A) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedStatus,
                            isExpanded: true,
                            dropdownColor: isDark ? const Color(0xFF221F3D) : Colors.white,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() => selectedStatus = val);
                              }
                            },
                            items: const [
                              DropdownMenuItem(
                                value: 'AGENCY-DONE',
                                child: Text('Successful (Process Withdrawal)'),
                              ),
                              DropdownMenuItem(
                                value: 'AGENCY-REJECT',
                                child: Text('Rejected'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'TRANSACTION ID / UTR',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF221F3D) : const Color(0xFFF8F7FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? const Color(0xFF332D4A) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: TextField(
                          controller: transactionIdController,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Enter Transaction / UTR reference number...',
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'AGENCY REMARK / NOTE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF221F3D) : const Color(0xFFF8F7FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? const Color(0xFF332D4A) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: TextField(
                          controller: remarkController,
                          maxLines: 2,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Enter remark note...',
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              remarkController.text = 'Withdrawal processed and completed successfully.';
                            },
                            icon: const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF10B981)),
                            label: const Text(
                              'Withdrawal processed and completed successfully.',
                              style: TextStyle(fontSize: 11),
                            ),
                            style: OutlinedButton.styleFrom(
                              alignment: Alignment.centerLeft,
                              foregroundColor: const Color(0xFF10B981),
                              side: const BorderSide(color: Color(0xFF10B981)),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                          ),
                          const SizedBox(height: 4),
                          OutlinedButton.icon(
                            onPressed: () {
                              remarkController.text = 'Account / Banking details mismatch.';
                            },
                            icon: const Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFF59E0B)),
                            label: const Text(
                              'Account / Banking details mismatch.',
                              style: TextStyle(fontSize: 11),
                            ),
                            style: OutlinedButton.styleFrom(
                              alignment: Alignment.centerLeft,
                              foregroundColor: const Color(0xFFF59E0B),
                              side: const BorderSide(color: Color(0xFFF59E0B)),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                          ),
                          const SizedBox(height: 4),
                          OutlinedButton.icon(
                            onPressed: () {
                              remarkController.text = 'Withdrawal request rejected.';
                            },
                            icon: const Icon(Icons.cancel, size: 14, color: Color(0xFFEF4444)),
                            label: const Text(
                              'Withdrawal request rejected.',
                              style: TextStyle(fontSize: 11),
                            ),
                            style: OutlinedButton.styleFrom(
                              alignment: Alignment.centerLeft,
                              foregroundColor: const Color(0xFFEF4444),
                              side: const BorderSide(color: Color(0xFFEF4444)),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: const Text('CANCEL'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isSubmitting
                                  ? null
                                  : () async {
                                      // Capture stable references before any async gaps
                                      final messenger = ScaffoldMessenger.of(context);

                                      setDialogState(() => isSubmitting = true);
                                      try {
                                        final apiClient = ApiClient();
                                        final rawId = item.id.replaceAll(RegExp(r'\D'), '');
                                        final remarkText = remarkController.text.trim();
                                        final transactionId = transactionIdController.text.trim();

                                        await apiClient.post(
                                          ApiEndpoints.getQrCode,
                                          data: {
                                            'action': 'edit_agency_withdraw_pending',
                                            'edit_agency_withdraw_pending': 1,
                                            'id': rawId,
                                            'agency_id': widget.userId ?? '',
                                            'amount': item.amount,
                                            'stage_status': selectedStatus,
                                            'transaction_id': transactionId,
                                            'remark': remarkText,
                                          },
                                        );
                                      } catch (_) {}

                                      // Use dialogContext.mounted to check if the dialog is still alive
                                      if (dialogContext.mounted) {
                                        Navigator.pop(dialogContext);
                                      }

                                      // Use widget's mounted to safely call setState
                                      if (mounted) {
                                        // Update local list state
                                        final cleanTargetId = item.id.replaceAll(RegExp(r'\D'), '');
                                        setState(() {
                                          final idx = _records.indexWhere((r) =>
                                              r.id == item.id ||
                                              r.id.replaceAll(RegExp(r'\D'), '') == cleanTargetId);
                                          if (idx != -1) {
                                            _records[idx] = RechargeRecordModel(
                                              id: _records[idx].id,
                                              bookName: _records[idx].bookName,
                                              userName: _records[idx].userName,
                                              transactionDetails: _records[idx].transactionDetails,
                                              amount: _records[idx].amount,
                                              status: selectedStatus,
                                              date: _records[idx].date,
                                              imageUrl: _records[idx].imageUrl,
                                              invoiceUrl: _records[idx].invoiceUrl,
                                            );
                                          }
                                        });

                                        final displayStatus = (selectedStatus == 'AGENCY-DONE' || selectedStatus == 'EMPLOYEE-DONE') ? 'Successful' : 'Rejected';
                                        final isSuccess = selectedStatus == 'AGENCY-DONE' || selectedStatus == 'EMPLOYEE-DONE';
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text('Withdrawal ${item.id} marked as $displayStatus successfully!'),
                                            backgroundColor: isSuccess ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                        refreshRecords();
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF59E0B),
                              ),
                              child: isSubmitting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Text('UPDATE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModalDetailRow(String label, String value, bool isDark, {bool isHighlight = false, bool isRed = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isHighlight || isRed ? 13 : 12.5,
              fontWeight: isHighlight || isRed ? FontWeight.w900 : FontWeight.w600,
              color: isRed
                  ? const Color(0xFFEF4444)
                  : (isHighlight
                      ? const Color(0xFFF59E0B)
                      : (isDark ? Colors.white : const Color(0xFF0F172A))),
            ),
          ),
        ),
      ],
    );
  }

  List<RechargeRecordModel> get _filteredRecords {
    return _records.where((record) {
      if (_selectedStatusFilter != 'all') {
        final statusLower = record.status.toLowerCase();
        final isDone = statusLower.contains('done') || statusLower.contains('successful') || statusLower.contains('approved');
        final isReject = statusLower.contains('reject') || statusLower.contains('failed') || statusLower.contains('declined');

        if (_selectedStatusFilter == 'pending' && (isDone || isReject)) {
          return false;
        } else if (_selectedStatusFilter == 'successful' && !isDone) {
          return false;
        } else if (_selectedStatusFilter == 'rejected' && !isReject) {
          return false;
        }
      }

      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchId = record.id.toLowerCase().contains(query);
        final matchBook = record.bookName.toLowerCase().contains(query);
        final matchDetails = record.transactionDetails.toLowerCase().contains(query);
        final matchAmount = record.amount.toString().contains(query);
        final matchUser = record.userName?.toLowerCase().contains(query) ?? false;

        return matchId || matchBook || matchDetails || matchAmount || matchUser;
      }

      return true;
    }).toList();
  }

  Widget _buildSkeletonRows(bool isDark) {
    return Column(
      children: List.generate(4, (index) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark ? const Color(0xFF1F1C36) : const Color(0xFFF1F5F9),
                width: 1,
              ),
            ),
          ),
          child: const Row(
            children: [
              Expanded(
                flex: 2,
                child: ShimmerBox(width: 40, height: 16, borderRadius: 6),
              ),
              SizedBox(width: 8),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 110, height: 14, borderRadius: 4),
                    SizedBox(height: 6),
                    ShimmerBox(width: 80, height: 12, borderRadius: 4),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ShimmerBox(width: 70, height: 20, borderRadius: 10),
                    SizedBox(height: 6),
                    ShimmerBox(width: 50, height: 10, borderRadius: 4),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ShimmerBox(width: 32, height: 32, borderRadius: 8),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _filteredRecords;

    final totalRecords = filtered.length;
    final totalPages = (totalRecords / _pageSize).ceil();
    final safePage = _currentPage > totalPages ? (totalPages == 0 ? 1 : totalPages) : _currentPage;
    final startIndex = (safePage - 1) * _pageSize;
    final endIndex = (startIndex + _pageSize > totalRecords) ? totalRecords : startIndex + _pageSize;
    final paginatedRecords = (startIndex < totalRecords) ? filtered.sublist(startIndex, endIndex) : <RechargeRecordModel>[];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14102B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF2D293E) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Banner
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_outlined,
                          color: Color(0xFFF59E0B),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Withdrawal Requests',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'Review and process pending client withdrawals',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: refreshRecords,
                  icon: const Icon(Icons.refresh_rounded, color: Color(0xFFF59E0B)),
                  tooltip: 'Refresh Withdrawals',
                ),
              ],
            ),
          ),

          // 2. Status Filter Chips Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildStatusPill(
                  label: 'All',
                  icon: Icons.grid_view_rounded,
                  statusValue: 'all',
                  isSelected: _selectedStatusFilter == 'all',
                  activeBg: const Color(0xFF232530),
                  activeFg: const Color(0xFF38BDF8),
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _buildStatusPill(
                  label: 'Pending',
                  icon: Icons.access_time_rounded,
                  statusValue: 'pending',
                  isSelected: _selectedStatusFilter == 'pending',
                  activeBg: const Color(0xFF232530),
                  activeFg: const Color(0xFFFFB800),
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _buildStatusPill(
                  label: 'Successful',
                  icon: Icons.check_circle_outline_rounded,
                  statusValue: 'successful',
                  isSelected: _selectedStatusFilter == 'successful',
                  activeBg: const Color(0xFF232530),
                  activeFg: const Color(0xFF10B981),
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _buildStatusPill(
                  label: 'Rejected',
                  icon: Icons.cancel_outlined,
                  statusValue: 'rejected',
                  isSelected: _selectedStatusFilter == 'rejected',
                  activeBg: const Color(0xFF232530),
                  activeFg: const Color(0xFFEF4444),
                  isDark: isDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          const Divider(height: 1, thickness: 0.8),
          const SizedBox(height: 16),

          // 3. Search & Showing Dropdown Controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1B2E) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? const Color(0xFF332D4A) : const Color(0xFFE2E8F0),
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
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          size: 18,
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                    _currentPage = 1;
                                  });
                                },
                                child: Icon(
                                  Icons.cancel_rounded,
                                  size: 18,
                                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                ),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Row(
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
                        color: isDark ? const Color(0xFF1E1B2E) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? const Color(0xFF332D4A) : const Color(0xFFCBD5E1),
                          width: 1,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _pageSize,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          dropdownColor: isDark ? const Color(0xFF1E1B2E) : Colors.white,
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
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4. Table Header & Rows (Mobile Responsive Horizontal Scroll)
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = constraints.maxWidth < 560;

              Widget tableContent = Column(
                children: [
                  // Table Header Row
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A1828) : const Color(0xFFFAF7F2),
                      border: Border.symmetric(
                        horizontal: BorderSide(
                          color: isDark ? const Color(0xFF2D293E) : const Color(0xFFF1EFE9),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'ID',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Text(
                            'WITHDRAWAL DETAILS',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'STATUS & DATE',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'ACTIONS',
                            textAlign: TextAlign.end,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Table Rows / Skeleton Loading / Empty
                  if (_isLoading)
                    _buildSkeletonRows(isDark)
                  else if (paginatedRecords.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.inbox_rounded,
                              size: 44,
                              color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No withdrawal requests found',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: paginatedRecords.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        color: isDark ? const Color(0xFF2D293E) : const Color(0xFFF1EFE9),
                      ),
                      itemBuilder: (context, index) {
                        final item = paginatedRecords[index];
                        final stUpper = item.status.toUpperCase();

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              // Withdrawal ID ONLY
                              Expanded(
                                flex: 2,
                                child: Text(
                                  item.id,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w900,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),

                              // Transaction Details & Amount
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
                                        color: Color(0xFFF59E0B),
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
                                    Builder(
                                      builder: (context) {
                                        if (stUpper.contains('EMPLOYEE-PENDING') ||
                                            stUpper.contains('EMPLOYEE-PASS') ||
                                            stUpper.contains('AGENCY-PENDING')) {
                                          return const Padding(
                                            padding: EdgeInsets.only(top: 3),
                                            child: Text(
                                              'Authority Not Verified Yet.',
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFFEF4444),
                                              ),
                                            ),
                                          );
                                        }
                                        return const SizedBox.shrink();
                                      },
                                    ),
                                  ],
                                ),
                              ),

                              // Status & Date
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
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
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: badgeBg,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            displayLabel,
                                            style: TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.bold,
                                              color: badgeFg,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.date,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Actions Column: View & Process Buttons
                              Expanded(
                                flex: 3,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      InkWell(
                                        onTap: () => _showViewDetailsModal(context, item),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                                              width: 1,
                                            ),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.visibility_rounded,
                                                color: Color(0xFFF59E0B),
                                                size: 14,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'View',
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFFF59E0B),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Builder(
                                        builder: (context) {
                                          final stUpper = item.status.toUpperCase();
                                          final isAlreadyProcessed = stUpper.contains('AGENCY-DONE') ||
                                              stUpper.contains('AGENCY-REJECT') ||
                                              stUpper.contains('EMPLOYEE-DONE') ||
                                              stUpper.contains('EMPLOYEE-REJECT') ||
                                              stUpper.contains('DONE') ||
                                              stUpper.contains('SUCCESSFUL') ||
                                              stUpper.contains('REJECTED');
                                          final canProcess = !isAlreadyProcessed &&
                                              (stUpper.contains('AGENCY-PENDING') || stUpper == 'PENDING' || stUpper.contains('EMPLOYEE-PASS'));

                                          if (!canProcess) return const SizedBox.shrink();

                                          return Padding(
                                            padding: const EdgeInsets.only(left: 6),
                                            child: InkWell(
                                              onTap: () => _showProcessWithdrawalModal(context, item),
                                              borderRadius: BorderRadius.circular(8),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: const Color(0xFF10B981).withValues(alpha: 0.5),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.check_circle_rounded,
                                                      color: Color(0xFF10B981),
                                                      size: 14,
                                                    ),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      'Process',
                                                      style: TextStyle(
                                                        fontSize: 11.5,
                                                        fontWeight: FontWeight.bold,
                                                        color: Color(0xFF10B981),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              );

              if (isSmallScreen) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: 560,
                    child: tableContent,
                  ),
                );
              }
              return tableContent;
            },
          ),

          // 6. Pagination Footer
          if (filtered.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Showing ${startIndex + 1} to $endIndex of $totalRecords entries',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: safePage > 1
                            ? () => setState(() => _currentPage--)
                            : null,
                        icon: const Icon(Icons.chevron_left_rounded),
                        color: const Color(0xFFF59E0B),
                        disabledColor: isDark ? const Color(0xFF332D4A) : const Color(0xFFCBD5E1),
                      ),
                      Text(
                        '$safePage / $totalPages',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      IconButton(
                        onPressed: safePage < totalPages
                            ? () => setState(() => _currentPage++)
                            : null,
                        icon: const Icon(Icons.chevron_right_rounded),
                        color: const Color(0xFFF59E0B),
                        disabledColor: isDark ? const Color(0xFF332D4A) : const Color(0xFFCBD5E1),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
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
    return InkWell(
      onTap: () {
        setState(() {
          _selectedStatusFilter = statusValue;
          _currentPage = 1;
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? activeBg
              : (isDark ? const Color(0xFF1E1B2E) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? activeFg
                : (isDark ? const Color(0xFF332D4A) : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? activeFg
                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? activeFg
                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
