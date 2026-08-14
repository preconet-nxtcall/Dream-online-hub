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
}
