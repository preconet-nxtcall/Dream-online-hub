class PaymentAccountModel {
  final String accountName;
  final String accountNo;
  final String ifscCode;
  final String bankName;
  final String upiId;
  final String? image;
  final String status;

  const PaymentAccountModel({
    this.accountName = '',
    this.accountNo = '',
    this.ifscCode = '',
    this.bankName = '',
    this.upiId = '',
    this.image,
    this.status = '',
  });

  bool get hasBankInfo {
    return bankName.trim().isNotEmpty ||
        accountNo.trim().isNotEmpty ||
        accountName.trim().isNotEmpty ||
        upiId.trim().isNotEmpty;
  }

  bool get isPendingApproval {
    final lower = status.trim().toLowerCase();
    return lower.contains('pending') || lower == '0' || lower == 'in_review' || lower == 'waiting';
  }

  bool get isApproved {
    final lower = status.trim().toLowerCase();
    if (isPendingApproval) return false;
    if (lower == 'approved' ||
        lower == 'success' ||
        lower == 'successful' ||
        lower == 'verified' ||
        lower == 'active' ||
        lower == 'accepted' ||
        lower == 'employee-approved' ||
        lower == '1' ||
        lower == 'true' ||
        lower == 'yes' ||
        lower == 'ok' ||
        lower == 'pass' ||
        lower == 'passed' ||
        lower == 'completed' ||
        lower == 'enable' ||
        lower == 'enabled' ||
        lower.contains('approved')) {
      return true;
    }
    if ((lower.isEmpty || lower == 'null') && hasBankInfo) {
      return true;
    }
    return false;
  }

  factory PaymentAccountModel.fromJson(Map<String, dynamic> json) {
    String extractStatus() {
      final keys = [
        'status',
        'approval_status',
        'is_approved',
        'approved',
        'bank_status',
        'account_status',
        'payout_status',
        'verify_status',
        'verification_status',
        'status_code',
        'status_text',
        'read_status',
        'readStatus',
        'stage_status',
        'state',
      ];
      for (final key in keys) {
        if (json.containsKey(key) && json[key] != null) {
          final val = json[key].toString().trim();
          if (val.isNotEmpty && val.toLowerCase() != 'null') {
            if (val == '1' || val.toLowerCase() == 'true') return 'APPROVED';
            return val;
          }
        }
      }
      return '';
    }

    return PaymentAccountModel(
      accountName: json['account_name']?.toString() ??
          json['accountHolderName']?.toString() ??
          json['account_holder_name']?.toString() ??
          json['holder_name']?.toString() ??
          json['name']?.toString() ??
          '',
      accountNo: json['account_no']?.toString() ??
          json['accountNumber']?.toString() ??
          json['account_number']?.toString() ??
          json['acc_no']?.toString() ??
          json['acc_number']?.toString() ??
          '',
      ifscCode: json['ifsc_code']?.toString() ??
          json['ifscCode']?.toString() ??
          json['ifsc']?.toString() ??
          '',
      bankName: json['bank_name']?.toString() ??
          json['bankName']?.toString() ??
          json['bank']?.toString() ??
          '',
      upiId: json['upi_id']?.toString() ??
          json['upiId']?.toString() ??
          json['upi']?.toString() ??
          '',
      image: json['image']?.toString() ??
          json['passbook_image']?.toString() ??
          json['passbook_photo']?.toString() ??
          json['qr_code']?.toString() ??
          json['imageUrl']?.toString() ??
          json['image_url']?.toString(),
      status: extractStatus(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'account_name': accountName,
      'account_no': accountNo,
      'ifsc_code': ifscCode,
      'bank_name': bankName,
      'upi_id': upiId,
      'image': image,
      'status': status,
    };
  }

  PaymentAccountModel copyWith({
    String? accountName,
    String? accountNo,
    String? ifscCode,
    String? bankName,
    String? upiId,
    String? image,
    String? status,
  }) {
    return PaymentAccountModel(
      accountName: accountName ?? this.accountName,
      accountNo: accountNo ?? this.accountNo,
      ifscCode: ifscCode ?? this.ifscCode,
      bankName: bankName ?? this.bankName,
      upiId: upiId ?? this.upiId,
      image: image ?? this.image,
      status: status ?? this.status,
    );
  }
}
