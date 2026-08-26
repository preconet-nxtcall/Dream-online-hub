class BaseResponse<T> {
  final bool status;
  final String message;
  final T? data;

  BaseResponse({
    required this.status,
    required this.message,
    this.data,
  });
}
