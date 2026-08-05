class ApiResponseDto<T> {
  final bool success;
  final int statusCode;
  final String message;
  final T? data;
  final dynamic errors;

  const ApiResponseDto({
    required this.success,
    required this.statusCode,
    required this.message,
    this.data,
    this.errors,
  });

  factory ApiResponseDto.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json) fromJsonT,
  ) {
    return ApiResponseDto<T>(
      success: json['success'] ?? true,
      statusCode: json['status_code'] ?? json['statusCode'] ?? 200,
      message: json['message'] ?? '',
      data: json['data'] != null ? fromJsonT(json['data']) : (json['result'] != null ? fromJsonT(json['result']) : null),
      errors: json['errors'],
    );
  }

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) {
    return {
      'success': success,
      'status_code': statusCode,
      'message': message,
      if (data != null) 'data': toJsonT(data as T),
      if (errors != null) 'errors': errors,
    };
  }
}
