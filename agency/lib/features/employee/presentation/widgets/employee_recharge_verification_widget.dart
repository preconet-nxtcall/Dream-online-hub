import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../models/user/recharge_record_model.dart';
import '../../../../providers/employee_provider.dart';

class EmployeeRechargeVerificationWidget extends StatefulWidget {
  const EmployeeRechargeVerificationWidget({super.key});

  @override
  State<EmployeeRechargeVerificationWidget> createState() =>
      _EmployeeRechargeVerificationWidgetState();
}

class _EmployeeRechargeVerificationWidgetState
    extends State<EmployeeRechargeVerificationWidget> {
  final TextEditingController _searchController = TextEditingController();
  int _displayedCount = 30;
  bool _isLoadingMore = false;
  String _lastSearch = '';
  String _lastFilter = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadMoreRecords(int totalCount) async {
    if (_isLoadingMore) return;
    setState(() {
      _isLoadingMore = true;
    });
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      setState(() {
        _displayedCount = (_displayedCount + 30).clamp(0, totalCount);
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmployeeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final records = provider.filteredRecharges;

    // Reset pagination when search query or filter changes
    if (_lastSearch != provider.rechargeSearchQuery ||
        _lastFilter != provider.rechargeFilter) {
      _lastSearch = provider.rechargeSearchQuery;
      _lastFilter = provider.rechargeFilter;
      _displayedCount = 30;
    }

    final totalCount = records.length;
    final paginatedRecords = records.take(_displayedCount).toList();
    final hasMore = _displayedCount < totalCount;

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels >=
                scrollInfo.metrics.maxScrollExtent - 250 &&
            !_isLoadingMore &&
            hasMore) {
          _loadMoreRecords(totalCount);
        }
        return false;
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search & Filter Section
          _buildSearchAndFilters(context, provider, isDark),
          const SizedBox(height: 12),

          // List Content
          if (provider.isLoadingRecharges && records.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF10B981),
                ),
              ),
            )
          else if (records.isEmpty)
            _buildEmptyState(isDark)
          else
            Column(
              children: [
                for (int i = 0; i < paginatedRecords.length; i++) ...[
                  _buildRechargeCard(context, paginatedRecords[i], isDark),
                  if (i < paginatedRecords.length - 1)
                    const SizedBox(height: 12),
                ],

                // Pagination Loading & Footer Status
                if (_isLoadingMore) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF18152D) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Color(0xFF10B981),
                            strokeWidth: 2,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Loading more recharges...',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (totalCount > 30) ...[
                  const SizedBox(height: 14),
                  Center(
                    child: Text(
                      hasMore
                          ? 'Showing ${_displayedCount.clamp(0, totalCount)} of $totalCount recharges • Scroll down for more'
                          : 'All $totalCount recharge records loaded',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFF64748B)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(
    BuildContext context,
    EmployeeProvider provider,
    bool isDark,
  ) {
    final bg = isDark ? const Color(0xFF18152D) : Colors.white;
    final border =
        isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0);

    return Column(
      children: [
        // Search bar
        Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (val) => provider.searchRecharges(val),
            style: TextStyle(
              fontSize: 13.5,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            decoration: InputDecoration(
              hintText: 'Search by Client, ID, UTR, Amount...',
              hintStyle: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Color(0xFF10B981),
                size: 20,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        provider.searchRecharges('');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 13),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Filter Pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildFilterChip(
                label: 'All Requests',
                value: 'all',
                count: provider.allRechargesCount,
                isSelected: provider.rechargeFilter == 'all',
                onSelected: () => provider.setRechargeFilter('all'),
                color: const Color(0xFF6366F1),
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'Pending',
                value: 'pending',
                count: provider.pendingRechargesCount,
                isSelected: provider.rechargeFilter == 'pending',
                onSelected: () => provider.setRechargeFilter('pending'),
                color: const Color(0xFFF59E0B),
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'Approved',
                value: 'successful',
                count: provider.successfulRechargesCount,
                isSelected: provider.rechargeFilter == 'successful',
                onSelected: () => provider.setRechargeFilter('successful'),
                color: const Color(0xFF10B981),
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'Rejected',
                value: 'rejected',
                count: provider.rejectedRechargesCount,
                isSelected: provider.rechargeFilter == 'rejected',
                onSelected: () => provider.setRechargeFilter('rejected'),
                color: const Color(0xFFEF4444),
                isDark: isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String value,
    required int count,
    required bool isSelected,
    required VoidCallback onSelected,
    required Color color,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onSelected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? color
              : (isDark ? const Color(0xFF1E1A38) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? color
                : (isDark ? const Color(0xFF2E2756) : const Color(0xFFE2E8F0)),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : const Color(0xFF475569)),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  color: isSelected ? Colors.white : color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRechargeCard(
    BuildContext context,
    RechargeRecordModel item,
    bool isDark,
  ) {
    final statusUpper = item.status.toUpperCase();
    final isApproved = statusUpper == 'EMPLOYEE-DONE' ||
        statusUpper == 'AGENCY-DONE' ||
        statusUpper.contains('DONE') ||
        statusUpper.contains('SUCCESS') ||
        statusUpper.contains('APPROV');
    final isReject = statusUpper.contains('REJECT') ||
        statusUpper.contains('FAIL') ||
        statusUpper.contains('DECLIN');
    final isAlreadyProcessed = isApproved || isReject;
    final canVerify = !isAlreadyProcessed;

    final Color statusColor;
    final String statusLabel;
    if (isApproved) {
      statusColor = const Color(0xFF10B981);
      statusLabel = (statusUpper == 'AGENCY-DONE')
          ? 'Agency Approved'
          : 'Employee Approved';
    } else if (isReject) {
      statusColor = const Color(0xFFEF4444);
      statusLabel = statusUpper.contains('AGENCY')
          ? 'Agency Rejected'
          : 'Employee Rejected';
    } else {
      statusColor = const Color(0xFFF59E0B);
      statusLabel = 'Pending Verification';
    }

    final cardBg = isDark ? const Color(0xFF18152D) : Colors.white;
    final borderColor =
        isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFECEAFE);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: canVerify
              ? const Color(0xFF10B981).withValues(alpha: 0.35)
              : borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => _showViewDetailsModal(context, item),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: User / Record ID and Status Badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.receipt_long_rounded,
                        color: statusColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.userName?.isNotEmpty == true
                                ? item.userName!
                                : 'Client Request',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Record ${item.id} • ${item.bookName}',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white54
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Amount and UTR Details Row
                Row(
                  children: [
                    // Amount
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AMOUNT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? Colors.white38
                                : const Color(0xFF94A3B8),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '₹${item.amount.toStringAsFixed(2)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TRANSACTION / UTR',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white38
                                  : const Color(0xFF94A3B8),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.transactionDetails.isNotEmpty
                                ? item.transactionDetails
                                : 'No UTR specified',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF334155),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Footer Row: Date & Action Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 13,
                          color:
                              isDark ? Colors.white38 : const Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.date,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? Colors.white38
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                    if (canVerify)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _showVerifyModal(context, item),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF10B981), Color(0xFF059669)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF10B981)
                                      .withValues(alpha: 0.45),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified_rounded,
                                  size: 15,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'VERIFY',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _showViewDetailsModal(context, item),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF221E42)
                                  : const Color(0xFFEEF2F6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF352F5B)
                                    : const Color(0xFFCBD5E1),
                                width: 1.1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.lock_outline_rounded,
                                  size: 13.5,
                                  color: isApproved
                                      ? const Color(0xFF10B981)
                                      : (isReject
                                          ? const Color(0xFFEF4444)
                                          : const Color(0xFF64748B)),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Locked & View',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? Colors.white70
                                        : const Color(0xFF334155),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Details Modal ────────────────────────────────────────────────────────
  void _showViewDetailsModal(BuildContext context, RechargeRecordModel item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF14102B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: const Color(0xFF10B981).withValues(alpha: 0.3),
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
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: Color(0xFF10B981),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Recharge Request Details',
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
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1C1838)
                      : const Color(0xFFF8F7FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF2E2756)
                        : const Color(0xFFECEAFE),
                  ),
                ),
                child: Column(
                  children: [
                    if (item.userName != null && item.userName!.isNotEmpty) ...[
                      _buildModalRow('Client Name', item.userName!, isDark),
                      const Divider(height: 16),
                    ],
                    _buildModalRow('Record ID', item.id, isDark),
                    const Divider(height: 16),
                    _buildModalRow('Platform / Book', item.bookName, isDark),
                    const Divider(height: 16),
                    _buildModalRow(
                        'Amount', '₹${item.amount.toStringAsFixed(2)}', isDark,
                        isHighlight: true),
                    const Divider(height: 16),
                    _buildModalRow(
                        'Transaction / UTR', item.transactionDetails, isDark),
                    const Divider(height: 16),
                    _buildModalRow('Date & Time', item.date, isDark),
                    const Divider(height: 16),
                    _buildModalRow('Status', item.status.toUpperCase(), isDark),
                    Builder(
                      builder: (context) {
                        final st = item.status.toUpperCase();
                        final isAlreadyProcessed = st.contains('AGENCY-DONE') ||
                            st.contains('EMPLOYEE-DONE') ||
                            st.contains('DONE') ||
                            st.contains('SUCCESS') ||
                            st.contains('APPROV') ||
                            st.contains('REJECT') ||
                            st.contains('FAIL');
                        if (isAlreadyProcessed) {
                          return Column(
                            children: [
                              const Divider(height: 16),
                              _buildModalRow(
                                  'Verification Lock',
                                  'Verified & Locked (One-Time Action Completed)',
                                  isDark,
                                  isHighlight: true),
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
                const SizedBox(height: 12),
                _buildViewScreenshotButton(context, item.imageUrl!, isDark),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(modalContext),
                      child: const Text('CLOSE'),
                    ),
                  ),
                  Builder(
                    builder: (context) {
                      final st = item.status.toUpperCase();
                      final isAlreadyProcessed = st.contains('AGENCY-DONE') ||
                          st.contains('EMPLOYEE-DONE') ||
                          st.contains('DONE') ||
                          st.contains('SUCCESS') ||
                          st.contains('APPROV') ||
                          st.contains('REJECT') ||
                          st.contains('FAIL');
                      if (isAlreadyProcessed) return const SizedBox.shrink();
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(modalContext);
                              _showVerifyModal(context, item);
                            },
                            icon: const Icon(Icons.verified_rounded,
                                size: 16, color: Colors.white),
                            label: const Text('VERIFY',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Verify Recharge Modal (Approve / Reject) ─────────────────────────────
  void _showVerifyModal(BuildContext context, RechargeRecordModel item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.read<EmployeeProvider>();

    String selectedStatus = 'EMPLOYEE-DONE';
    final utrController = TextEditingController(text: item.transactionDetails);
    final remarkController = TextEditingController(
      text: 'Payment verified and recharge approved successfully.',
    );
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF14102B) : Colors.white,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: SingleChildScrollView(
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
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.verified_rounded,
                              color: Color(0xFF10B981),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Employee Recharge Verification',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  'Record ${item.id} • Amount: ₹${item.amount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(dialogContext),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Verification Decision
                      Text(
                        'CHOOSE ACTION',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color:
                              isDark ? Colors.white70 : const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF221F3D)
                              : const Color(0xFFF8F7FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF332D4A)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedStatus,
                            isExpanded: true,
                            dropdownColor:
                                isDark ? const Color(0xFF221F3D) : Colors.white,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() {
                                  selectedStatus = val;
                                  if (val == 'EMPLOYEE-DONE') {
                                    remarkController.text =
                                        'Payment verified and recharge approved successfully.';
                                  } else if (val == 'EMPLOYEE-REJECT') {
                                    remarkController.text =
                                        'Payment not received in bank account / UTR mismatch.';
                                  }
                                });
                              }
                            },
                            items: const [
                              DropdownMenuItem(
                                value: 'EMPLOYEE-DONE',
                                child: Text('Approve Recharge (EMPLOYEE-DONE)'),
                              ),
                              DropdownMenuItem(
                                value: 'EMPLOYEE-REJECT',
                                child:
                                    Text('Reject Recharge (EMPLOYEE-REJECT)'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // UTR Input
                      Text(
                        'UTR / TRANSACTION ID',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color:
                              isDark ? Colors.white70 : const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF221F3D)
                              : const Color(0xFFF8F7FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF332D4A)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: TextField(
                          controller: utrController,
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Enter verified UTR number...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Employee Remark
                      Text(
                        'EMPLOYEE REMARK / NOTE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color:
                              isDark ? Colors.white70 : const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF221F3D)
                              : const Color(0xFFF8F7FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF332D4A)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: TextField(
                          controller: remarkController,
                          maxLines: 2,
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Enter employee note...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Quick remark presets
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          ActionChip(
                            label: const Text('Payment Verified',
                                style: TextStyle(fontSize: 11)),
                            avatar: const Icon(Icons.check,
                                size: 13, color: Color(0xFF10B981)),
                            onPressed: () {
                              setDialogState(() {
                                selectedStatus = 'EMPLOYEE-DONE';
                                remarkController.text =
                                    'Payment verified and recharge approved.';
                              });
                            },
                          ),
                          ActionChip(
                            label: const Text('UTR Mismatch',
                                style: TextStyle(fontSize: 11)),
                            avatar: const Icon(Icons.close,
                                size: 13, color: Color(0xFFEF4444)),
                            onPressed: () {
                              setDialogState(() {
                                selectedStatus = 'EMPLOYEE-REJECT';
                                remarkController.text =
                                    'UTR / Transaction ID mismatch.';
                              });
                            },
                          ),
                          ActionChip(
                            label: const Text('Payment Not Received',
                                style: TextStyle(fontSize: 11)),
                            avatar: const Icon(Icons.warning_amber_rounded,
                                size: 13, color: Color(0xFFF59E0B)),
                            onPressed: () {
                              setDialogState(() {
                                selectedStatus = 'EMPLOYEE-REJECT';
                                remarkController.text =
                                    'Payment not received in bank account.';
                              });
                            },
                          ),
                        ],
                      ),
                      // Payment proof preview if available
                      if (item.imageUrl != null &&
                          item.imageUrl!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildViewScreenshotButton(
                            context, item.imageUrl!, isDark),
                      ],
                      const SizedBox(height: 20),

                      // Submit buttons
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
                                      final messenger =
                                          ScaffoldMessenger.of(context);
                                      setDialogState(() => isSubmitting = true);

                                      await provider.verifyRecharge(
                                        item: item,
                                        newStatus: selectedStatus,
                                        remark: remarkController.text.trim(),
                                        transactionId:
                                            utrController.text.trim(),
                                      );

                                      if (dialogContext.mounted) {
                                        Navigator.pop(dialogContext);
                                      }

                                      final isApproved =
                                          selectedStatus == 'EMPLOYEE-DONE';
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Recharge ${item.id} ${isApproved ? "Approved" : "Rejected"} successfully!',
                                          ),
                                          backgroundColor: isApproved
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFFEF4444),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    selectedStatus == 'EMPLOYEE-DONE'
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFEF4444),
                              ),
                              child: isSubmitting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'SUBMIT',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
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

  Widget _buildModalRow(
    String label,
    String value,
    bool isDark, {
    bool isHighlight = false,
  }) {
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
              fontSize: isHighlight ? 14 : 12.5,
              fontWeight: isHighlight ? FontWeight.w900 : FontWeight.w600,
              color: isHighlight
                  ? const Color(0xFF10B981)
                  : (isDark ? Colors.white : const Color(0xFF0F172A)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
            const SizedBox(height: 12),
            Text(
              'No Recharge Requests Found',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : const Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'No recharge requests match the current filter.',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewScreenshotButton(
      BuildContext context, String imageUrl, bool isDark) {
    return InkWell(
      onTap: () =>
          _showImagePreviewDialog(context, imageUrl, 'Payment Screenshot'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color:
              const Color(0xFF6366F1).withValues(alpha: isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF6366F1).withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                size: 18,
                color: Color(0xFF6366F1),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Click to View Payment Screenshot',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                  Text(
                    'Tap to inspect full proof & zoom',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white54 : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.open_in_new_rounded,
              size: 16,
              color: Color(0xFF6366F1),
            ),
          ],
        ),
      ),
    );
  }

  void _showImagePreviewDialog(
      BuildContext context, String imageUrl, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF16122E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color:
                    isDark ? const Color(0xFF332D4A) : const Color(0xFFE2E8F0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 10, 10),
                  child: Row(
                    children: [
                      const Icon(Icons.image_outlined,
                          size: 20, color: Color(0xFF6366F1)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color:
                                isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.pop(dialogCtx),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(20)),
                    child: Container(
                      color: isDark
                          ? const Color(0xFF0F0B1E)
                          : const Color(0xFFF8FAFC),
                      constraints: const BoxConstraints(maxHeight: 450),
                      width: double.infinity,
                      child: InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(40),
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.broken_image_rounded,
                                      size: 40,
                                      color: isDark
                                          ? Colors.white30
                                          : Colors.black26,
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Failed to load image',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
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
}
