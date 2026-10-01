class RechargeRecordModel {
  final String id;
  final String bookName;
  final String transactionDetails;
  final double amount;
  final String status; // 'pending' or 'successful'
  final String date;
  final String? imageUrl;
  final String? invoiceUrl;
  final String? userName;

  const RechargeRecordModel({
    required this.id,
    required this.bookName,
    required this.transactionDetails,
    required this.amount,
    required this.status,
    required this.date,
    this.imageUrl,
    this.invoiceUrl,
    this.userName,
  });

  factory RechargeRecordModel.fromJson(Map<String, dynamic> json) {
    return RechargeRecordModel(
      id: (json['id'] ?? json['recharge_id'] ?? '#1').toString(),
      bookName: (json['book_name'] ?? json['bookName'] ?? 'Lucky Vault').toString(),
      transactionDetails: (json['transaction_details'] ?? json['transactionDetails'] ?? 'UPI Deposit').toString(),
      amount: (json['amount'] is num) ? (json['amount'] as num).toDouble() : double.tryParse(json['amount'].toString()) ?? 0.0,
      status: (json['status'] ?? json['stage_status'] ?? 'pending').toString().toLowerCase(),
      date: (json['formatted_date'] ?? json['date'] ?? '08 Aug 2026').toString(),
      imageUrl: json['image_url']?.toString(),
      invoiceUrl: json['invoice_url']?.toString(),
      userName: (json['user_name'] ?? json['userName'] ?? json['user'] ?? json['name'] ?? json['email'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'book_name': bookName,
      'transaction_details': transactionDetails,
      'amount': amount,
      'status': status,
      'date': date,
      'image_url': imageUrl,
      'invoice_url': invoiceUrl,
      'user_name': userName,
    };
  }

  /// Auto-detects whether this record is a withdrawal (ID starts with W / #W or details contain withdrawal).
  bool get isWithdrawal =>
      id.toUpperCase().startsWith('#W') ||
      id.toUpperCase().startsWith('W') ||
      transactionDetails.toLowerCase().contains('withdraw');

  /// Evaluates whether the record is FULLY APPROVED.
  /// For Recharge: Agency-only approval ('AGENCY-DONE') is PENDING until Employee completes approval ('EMPLOYEE-DONE').
  /// For Withdrawal: 'AGENCY-DONE' or 'EMPLOYEE-DONE' represents complete approval (SUCCESSFUL).
  bool get isFullyApproved => isRechargeFullyApproved(status, isWithdrawal: isWithdrawal);

  /// Helper to check if a status string represents complete approval.
  static bool isRechargeFullyApproved(String statusStr, {bool isWithdrawal = false}) {
    final s = statusStr.trim().toLowerCase();

    // 1. If explicit pending keywords are present, it is NOT fully approved
    if (s.contains('pending') || s.contains('process') || s.contains('wait')) {
      return false;
    }

    // 2. If rejected
    if (s.contains('reject') || s.contains('failed') || s.contains('declined') || s.contains('cancel')) {
      return false;
    }

    // 3. For RECHARGE ONLY: Agency-only approval ('AGENCY-DONE' or 'AGENCY-APPROVED') is NOT fully approved.
    // It requires Employee completion ('EMPLOYEE-DONE' / 'BOTH-APPROVED' / 'SUCCESSFUL').
    if (!isWithdrawal) {
      if (s == 'agency-done' ||
          s == 'agency_done' ||
          s.contains('agency-done') ||
          s.contains('agency_done') ||
          s.contains('agency-approved') ||
          s.contains('agency_approved') ||
          s.contains('agency approved') ||
          s.contains('approved_by_agency')) {
        if (!s.contains('emp') && !s.contains('both') && !s.contains('full')) {
          return false;
        }
      }
      if ((s.contains('employee-approved') || s.contains('emp-approved') || s.contains('emp_approved') || s.contains('approved_by_employee')) &&
          !s.contains('agency') && !s.contains('both') && !s.contains('full')) {
        return false;
      }
    }

    // 4. Complete approval check:
    // For Withdrawal: 'AGENCY-DONE' or 'EMPLOYEE-DONE' or 'SUCCESSFUL' or 'APPROVED'
    // For Recharge: 'EMPLOYEE-DONE' or 'BOTH-APPROVED' or 'SUCCESSFUL' or 'APPROVED'
    return s == '1' ||
        s == 'true' ||
        (isWithdrawal && (s == 'agency-done' || s == 'agency_done' || s.contains('agency-done') || s.contains('agency_done'))) ||
        s == 'employee-done' ||
        s == 'employee_done' ||
        s == 'emp-done' ||
        s == 'emp_done' ||
        s == 'successful' ||
        s == 'success' ||
        s == 'done' ||
        s == 'completed' ||
        s == 'finished' ||
        s == 'both-approved' ||
        s == 'both_approved' ||
        s == 'fully-approved' ||
        s == 'fully_approved' ||
        s == 'approved' ||
        s.contains('employee-done') ||
        s.contains('employee_done') ||
        s.contains('emp-done') ||
        s.contains('both-approved') ||
        s.contains('both_approved') ||
        s.contains('fully-approved') ||
        s.contains('successful') ||
        (s.contains('agency') && (s.contains('emp') || s.contains('employee')) && (s.contains('approve') || s.contains('done'))) ||
        (s.contains('approved') && !s.contains('pending') && !s.contains('agency') && !s.contains('emp'));
  }
}
