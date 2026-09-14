import '../../core/constants/api_endpoints.dart';

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

  bool get isRejected {
    final lower = status.trim().toLowerCase();
    return lower.contains('reject') ||
        lower.contains('declin') ||
        lower.contains('disapprov') ||
        lower.contains('fail') ||
        lower.contains('block') ||
        lower == '2';
  }

  bool get isApproved {
    final lower = status.trim().toLowerCase();
    if (isPendingApproval || isRejected) return false;
    if (lower == 'approved' ||
        lower == 'approve' ||
        lower == 'success' ||
        lower == 'successful' ||
        lower == 'verified' ||
        lower == 'active' ||
        lower == 'accepted' ||
        lower == 'employee-approved' ||
        lower == 'employee-approve' ||
        lower == 'agency-approve' ||
        lower == '1' ||
        lower == 'true' ||
        lower == 'yes' ||
        lower == 'ok' ||
        lower == 'pass' ||
        lower == 'passed' ||
        lower == 'completed' ||
        lower == 'enable' ||
        lower == 'enabled' ||
        lower.contains('approv') ||
        lower.contains('done')) {
      return true;
    }
    if ((lower.isEmpty || lower == 'null' || lower == 'read') && hasBankInfo) {
      return true;
    }
    return false;
  }

  factory PaymentAccountModel.fromJson(Map<String, dynamic> json) {
    String extractStatus() {
      final keys = [
        'status',
        'stage_status',
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
        'state',
        'read_status',
        'readStatus',
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

    final Map<String, String> parsedBankDetail = {};
    final rawDetail = json['bank_detail'] ??
        json['bank_details'] ??
        json['deatil'] ??
        json['detail'] ??
        json['details'] ??
        json['bank_info'];

    if (rawDetail != null) {
      if (rawDetail is Map<String, dynamic>) {
        rawDetail.forEach((k, v) {
          if (v != null) parsedBankDetail[k.toString().toLowerCase()] = v.toString().trim();
        });
      } else if (rawDetail is String) {
        final str = rawDetail.toString();
        final parts = str.split(RegExp(r'[,;\n]'));
        for (final part in parts) {
          final kv = part.split(':');
          if (kv.length >= 2) {
            final key = kv[0].trim().toLowerCase();
            final val = kv.sublist(1).join(':').trim();
            if (key.contains('account name') || key.contains('holder') || key == 'name' || key == 'account_name') {
              parsedBankDetail['account_name'] = val;
            } else if (key.contains('account no') ||
                key.contains('acc no') ||
                key.contains('acc. no') ||
                key.contains('account number') ||
                key.contains('acc number') ||
                key == 'acc' ||
                key == 'account_no' ||
                key == 'acc_no') {
              parsedBankDetail['account_no'] = val;
            } else if (key.contains('ifsc')) {
              parsedBankDetail['ifsc_code'] = val;
            } else if (key.contains('bank')) {
              parsedBankDetail['bank_name'] = val;
            } else if (key.contains('upi') || key.contains('vpa')) {
              parsedBankDetail['upi_id'] = val;
            }
          }
        }
      }
    }

    String getFirstNonEmpty(List<dynamic> candidates) {
      for (final cand in candidates) {
        if (cand != null) {
          final val = cand.toString().trim();
          if (val.isNotEmpty && val.toLowerCase() != 'null') {
            return val;
          }
        }
      }
      return '';
    }

    final accountName = getFirstNonEmpty([
      json['account_name'],
      json['accountHolderName'],
      json['account_holder_name'],
      json['holder_name'],
      json['name'],
      parsedBankDetail['account_name'],
    ]);

    final accountNo = getFirstNonEmpty([
      json['account_no'],
      json['accountNumber'],
      json['account_number'],
      json['acc_no'],
      json['acc_number'],
      parsedBankDetail['account_no'],
    ]);

    final ifscCode = getFirstNonEmpty([
      json['ifsc_code'],
      json['ifscCode'],
      json['ifsc'],
      parsedBankDetail['ifsc_code'],
    ]);

    final bankName = getFirstNonEmpty([
      json['bank_name'],
      json['bankName'],
      json['bank'],
      parsedBankDetail['bank_name'],
    ]);

    final upiId = getFirstNonEmpty([
      json['upi_id'],
      json['upiId'],
      json['upi'],
      parsedBankDetail['upi_id'],
    ]);

    final rawImage = getFirstNonEmpty([
      json['image'],
      json['passbook_image'],
      json['passbook_photo'],
      json['qr_code'],
      json['imageUrl'],
      json['image_url'],
      json['qr_image_url'],
    ]);

    String? formattedImage;
    if (rawImage.isNotEmpty) {
      formattedImage = rawImage.trim();
      if (!formattedImage.startsWith('http://') &&
          !formattedImage.startsWith('https://') &&
          !formattedImage.startsWith('data:')) {
        final cleanPath = formattedImage.startsWith('/') ? formattedImage.substring(1) : formattedImage;
        if (cleanPath.startsWith('uploads/')) {
          formattedImage = '${ApiEndpoints.baseUrl}$cleanPath';
        } else {
          formattedImage = '${ApiEndpoints.baseUrl}uploads/photos/$cleanPath';
        }
      }
    }

    return PaymentAccountModel(
      accountName: accountName,
      accountNo: accountNo,
      ifscCode: ifscCode,
      bankName: bankName,
      upiId: upiId,
      image: formattedImage,
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
