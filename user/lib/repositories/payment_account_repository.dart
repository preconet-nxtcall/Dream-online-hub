import 'package:dio/dio.dart';
import '../core/constants/api_endpoints.dart';
import '../models/user/payment_account_model.dart';
import '../network/api_client.dart';
import '../utils/logger.dart';

abstract class PaymentAccountRepository {
  Future<PaymentAccountModel?> getPaymentAccount(dynamic userId);
  Future<bool> updatePaymentAccount({
    required dynamic userId,
    required String accountName,
    required String accountNo,
    required String ifscCode,
    required String bankName,
    required String upiId,
    String? imageBase64,
  });
}

class PaymentAccountRepositoryImpl implements PaymentAccountRepository {
  final ApiClient _apiClient;

  PaymentAccountRepositoryImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  @override
  Future<PaymentAccountModel?> getPaymentAccount(dynamic userId) async {
    if (userId == null || userId.toString().trim().isEmpty) {
      AppLogger.warning('getPaymentAccount: No user_id provided.');
      return null;
    }

    try {
      final options = Options(validateStatus: (status) => status != null && status < 500);
      final rawUserId = userId.toString().trim();

      var response = await _apiClient.post(
        ApiEndpoints.getQrCode, // api.php
        options: options,
        data: {
          'action': 'get_payment_account',
          'user_id': rawUserId,
        },
      );

      var data = response.data;
      if (response.statusCode == 400 || data is! Map<String, dynamic> || data['success'] != true) {
        // Fallback retry with formUrlEncoded Content-Type for standard PHP $_POST
        try {
          final formResp = await _apiClient.post(
            ApiEndpoints.getQrCode,
            options: Options(
              contentType: Headers.formUrlEncodedContentType,
              validateStatus: (status) => status != null && status < 500,
            ),
            data: {
              'action': 'get_payment_account',
              'user_id': rawUserId,
            },
          );
          if (formResp.data is Map<String, dynamic> && formResp.data['success'] == true) {
            data = formResp.data;
          }
        } catch (_) {}
      }

      if (data is Map<String, dynamic>) {
        if (data['success'] == true ||
            data.containsKey('account_name') ||
            data.containsKey('bank_name') ||
            data.containsKey('data')) {
          final accountData = (data['data'] is Map<String, dynamic>)
              ? data['data'] as Map<String, dynamic>
              : (data['payment_account'] is Map<String, dynamic>)
                  ? data['payment_account'] as Map<String, dynamic>
                  : (data['bank_details'] is Map<String, dynamic>)
                      ? data['bank_details'] as Map<String, dynamic>
                      : (data['account'] is Map<String, dynamic>)
                          ? data['account'] as Map<String, dynamic>
                          : (data['bank_account'] is Map<String, dynamic>)
                              ? data['bank_account'] as Map<String, dynamic>
                              : (data['user_account'] is Map<String, dynamic>)
                                  ? data['user_account'] as Map<String, dynamic>
                                  : data;

          return PaymentAccountModel.fromJson(accountData);
        }
      }
      return null;
    } catch (e) {
      AppLogger.error('Failed to fetch payment account: $e');
      return null;
    }
  }

  @override
  Future<bool> updatePaymentAccount({
    required dynamic userId,
    required String accountName,
    required String accountNo,
    required String ifscCode,
    required String bankName,
    required String upiId,
    String? imageBase64,
  }) async {
    if (userId == null || userId.toString().trim().isEmpty) {
      AppLogger.error('updatePaymentAccount: Cannot update payment account because user_id is empty.');
      return false;
    }

    try {
      final rawUserId = userId.toString().trim();
      final options = Options(validateStatus: (status) => status != null && status < 500);
      final payload = {
        'action': 'update_payment_account',
        'user_id': rawUserId,
        'account_name': accountName,
        'account_no': accountNo,
        'ifsc_code': ifscCode,
        'bank_name': bankName,
        'upi_id': upiId,
        if (imageBase64 != null && imageBase64.isNotEmpty) 'image': imageBase64,
      };

      var response = await _apiClient.post(
        ApiEndpoints.getQrCode, // api.php
        options: options,
        data: payload,
      );

      var data = response.data;
      if (response.statusCode == 400 || data is! Map<String, dynamic> || data['success'] != true) {
        // Fallback retry with formUrlEncoded Content-Type for standard PHP $_POST
        try {
          final formMap = {
            'action': 'update_payment_account',
            'user_id': rawUserId,
            'account_name': accountName,
            'account_no': accountNo,
            'ifsc_code': ifscCode,
            'bank_name': bankName,
            'upi_id': upiId,
            if (imageBase64 != null && imageBase64.isNotEmpty) 'image': imageBase64,
          };
          final formResp = await _apiClient.post(
            ApiEndpoints.getQrCode,
            options: Options(
              contentType: Headers.formUrlEncodedContentType,
              validateStatus: (status) => status != null && status < 500,
            ),
            data: formMap,
          );
          if (formResp.data is Map<String, dynamic> && formResp.data['success'] == true) {
            data = formResp.data;
          }
        } catch (_) {}
      }

      if (data is Map<String, dynamic>) {
        if (data['success'] == true || data['status'] == true || response.statusCode == 200) {
          return true;
        }
      }
      return true;
    } catch (e) {
      AppLogger.error('Failed to update payment account: $e');
      return false;
    }
  }
}
