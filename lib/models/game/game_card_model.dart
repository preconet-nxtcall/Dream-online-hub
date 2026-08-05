class GameCardModel {
  final String id;
  final String name;
  final String code; // 2-letter badge e.g. MI, KA, SR
  final String result; // e.g. ***-**-*** or 140-59-234
  final String status; // 'Running Open', 'Closed', 'Running Close'
  final bool isOpen;
  final String openTime;
  final String closeTime;
  final String? imageUrl;
  final String category; // 'Main Markets', 'Starline', 'Jackpot'

  const GameCardModel({
    required this.id,
    required this.name,
    required this.code,
    required this.result,
    required this.status,
    required this.isOpen,
    required this.openTime,
    required this.closeTime,
    this.imageUrl,
    this.category = 'Main Markets',
  });

  factory GameCardModel.fromJson(Map<String, dynamic> json) {
    return GameCardModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? json['title'] ?? 'Game Market').toString(),
      code: (json['code'] ?? (json['name'] != null && json['name'].toString().length >= 2
          ? json['name'].toString().substring(0, 2).toUpperCase()
          : 'GM')).toString(),
      result: (json['result'] ?? json['numbers'] ?? '***-**-***').toString(),
      status: (json['status'] ?? 'Running Open').toString(),
      isOpen: json['is_open'] ?? json['isOpen'] ?? true,
      openTime: (json['open_time'] ?? json['openTime'] ?? '10:30 AM').toString(),
      closeTime: (json['close_time'] ?? json['closeTime'] ?? '11:30 AM').toString(),
      imageUrl: json['image_url'] ?? json['imageUrl'],
      category: (json['category'] ?? 'Main Markets').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'result': result,
      'status': status,
      'is_open': isOpen,
      'open_time': openTime,
      'close_time': closeTime,
      if (imageUrl != null) 'image_url': imageUrl,
      'category': category,
    };
  }
}
