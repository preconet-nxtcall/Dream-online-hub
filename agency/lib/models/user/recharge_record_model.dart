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
  final String? userId;
  final String? empId;
  final String? agencyId;
  final String? accountHolderName;
  final String? accountNumber;
  final String? bankName;
  final String? ifscCode;
  final String? upiId;

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
    this.userId,
    this.empId,
    this.agencyId,
    this.accountHolderName,
    this.accountNumber,
    this.bankName,
    this.ifscCode,
    this.upiId,
  });

  factory RechargeRecordModel.fromJson(Map<String, dynamic> json) {
    final rawImg = json['image_url'] ?? json['imageUrl'] ?? json['image'];
    String? resolvedImg;
    if (rawImg != null &&
        rawImg.toString().isNotEmpty &&
        rawImg.toString() != 'null') {
      final str = rawImg.toString();
      if (str.startsWith('http')) {
        resolvedImg = str;
      } else {
        resolvedImg = 'https://dreamonlinehub.club/uploads/photos/$str';
      }
    }

    final rawInvoice =
        json['invoice_url'] ?? json['invoiceUrl'] ?? json['invoice'];
    String? resolvedInvoice;
    if (rawInvoice != null &&
        rawInvoice.toString().isNotEmpty &&
        rawInvoice.toString() != 'null') {
      final str = rawInvoice.toString();
      if (str.startsWith('http')) {
        resolvedInvoice = str;
      } else {
        resolvedInvoice = 'https://dreamonlinehub.club/uploads/documents/$str';
      }
    }

    final rawHolder = json['user_ac_holder_name'] ??
        json['account_name'] ??
        json['account_holder_name'] ??
        json['ac_holder_name'];
    final rawAcNum = json['user_ac_number'] ??
        json['account_no'] ??
        json['account_number'] ??
        json['ac_number'];
    final rawBank = json['user_bank_name'] ?? json['bank_name'] ?? json['bank'];
    final rawIfsc = json['user_bank_ifsc'] ?? json['ifsc_code'] ?? json['ifsc'];
    final rawUpi = json['user_upi_id'] ?? json['upi_id'] ?? json['upi'];

    return RechargeRecordModel(
      id: (json['id'] ?? json['recharge_id'] ?? json['withdrawal_id'] ?? '#1')
          .toString(),
      bookName: (json['book_name'] ??
              json['bookName'] ??
              json['book'] ??
              'Official Portal')
          .toString(),
      transactionDetails: (json['transaction_details'] ??
              json['transactionDetails'] ??
              json['deatil'] ??
              json['detail'] ??
              json['transection_id'] ??
              json['transaction_id'] ??
              'Payment Transaction')
          .toString(),
      amount: (json['amount'] is num)
          ? (json['amount'] as num).toDouble()
          : double.tryParse(json['amount'].toString()) ?? 0.0,
      status: (json['stage_status'] ?? json['status'] ?? 'pending').toString(),
      date: (json['formatted_date'] ?? json['date'] ?? 'Just now').toString(),
      imageUrl: resolvedImg,
      invoiceUrl: resolvedInvoice,
      userName: (json['user_name'] ??
              json['userName'] ??
              json['user'] ??
              json['name'] ??
              json['email'])
          ?.toString(),
      userId: (json['user_id'] ?? json['userId'])?.toString(),
      empId: json['emp_id']?.toString(),
      agencyId: json['agency_id']?.toString(),
      accountHolderName: rawHolder?.toString(),
      accountNumber: rawAcNum?.toString(),
      bankName: rawBank?.toString(),
      ifscCode: rawIfsc?.toString(),
      upiId: rawUpi?.toString(),
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
      if (imageUrl != null) 'image_url': imageUrl,
      if (invoiceUrl != null) 'invoice_url': invoiceUrl,
      if (userName != null) 'user_name': userName,
      if (userId != null) 'user_id': userId,
      if (empId != null) 'emp_id': empId,
      if (agencyId != null) 'agency_id': agencyId,
      if (accountHolderName != null) 'user_ac_holder_name': accountHolderName,
      if (accountNumber != null) 'user_ac_number': accountNumber,
      if (bankName != null) 'user_bank_name': bankName,
      if (ifscCode != null) 'user_bank_ifsc': ifscCode,
      if (upiId != null) 'user_upi_id': upiId,
    };
  }
}
