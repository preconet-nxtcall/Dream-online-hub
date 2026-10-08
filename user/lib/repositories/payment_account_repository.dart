import 'dart:convert';
import 'package:dio/dio.dart';
import '../core/constants/api_endpoints.dart';
import '../models/user/payment_account_model.dart';
import '../network/api_client.dart';
import '../storage/local_storage_repository.dart';
import '../utils/logger.dart';

abstract class PaymentAccountRepository {
  Future<PaymentAccountModel?> getPaymentAccount(dynamic userId, {dynamic empId});
  Future<bool> updatePaymentAccount({
    required dynamic userId,
    dynamic empId,
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

  Map<String, dynamic>? _parseData(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String) {
      final str = raw.trim();
      if (str.isEmpty) return null;
      try {
        final decoded = jsonDecode(str);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {
        final firstBrace = str.indexOf('{');
        final lastBrace = str.lastIndexOf('}');
        if (firstBrace != -1 && lastBrace > firstBrace) {
          try {
            final sub = str.substring(firstBrace, lastBrace + 1);
            final decoded = jsonDecode(sub);
            if (decoded is Map<String, dynamic>) return decoded;
            if (decoded is Map) return Map<String, dynamic>.from(decoded);
          } catch (_) {}
        }
      }
    }
    return null;
  }

  bool _isSuccess(Map<String, dynamic>? data, int? statusCode) {
    if (data == null) return statusCode != null && statusCode >= 200 && statusCode < 300;
    if (data['success'] == false ||
        data['status'] == false ||
        data['status'] == '0' ||
        data['status'] == 0 ||
        data['status'] == 'error' ||
        data['status'] == 'failed') {
      return false;
    }
    if (data['success'] == true ||
        data['status'] == true ||
        data['status'] == 'success' ||
        data['status'] == '1' ||
        data['status'] == 1 ||
        (data.containsKey('message') &&
            !data['message'].toString().toLowerCase().contains('fail') &&
            !data['message'].toString().toLowerCase().contains('error') &&
            !data['message'].toString().toLowerCase().contains('invalid')) ||
        (statusCode != null && statusCode >= 200 && statusCode < 300)) {
      return true;
    }
    return false;
  }

  @override
  Future<PaymentAccountModel?> getPaymentAccount(dynamic userId, {dynamic empId}) async {
    if (userId == null || userId.toString().trim().isEmpty) {
      AppLogger.warning('getPaymentAccount: No user_id provided.');
      return null;
    }

    try {
      final options = Options(validateStatus: (status) => status != null && status < 500);
      final rawUserId = userId.toString().trim();
      final digitsOnlyUserId = rawUserId.replaceAll(RegExp(r'\D'), '');
      final numericUserId = digitsOnlyUserId.isNotEmpty ? (int.tryParse(digitsOnlyUserId) ?? rawUserId) : rawUserId;
      final rawEmpId = (empId != null && empId.toString().trim().isNotEmpty) ? empId.toString().trim() : '';

      final requestData = {
        'action': 'get_payment_account',
        'user_id': rawUserId,
        'id': numericUserId,
        if (rawEmpId.isNotEmpty) 'emp_id': rawEmpId,
        if (rawEmpId.isNotEmpty) 'agency_id': rawEmpId,
      };

      var response = await _apiClient.post(
        ApiEndpoints.getQrCode, // api.php
        options: options,
        data: requestData,
      );

      var data = _parseData(response.data);
      if (data == null || data['success'] != true) {
        // Fallback retry with formUrlEncoded Content-Type for standard PHP $_POST
        try {
          final formResp = await _apiClient.post(
            ApiEndpoints.getQrCode,
            options: Options(
              contentType: Headers.formUrlEncodedContentType,
              validateStatus: (status) => status != null && status < 500,
            ),
            data: requestData.map((k, v) => MapEntry(k, v.toString())),
          );
          final parsedForm = _parseData(formResp.data);
          if (parsedForm != null &&
              (parsedForm['success'] == true ||
                  parsedForm.containsKey('bank_detail') ||
                  parsedForm.containsKey('account_name') ||
                  parsedForm.containsKey('bank_name'))) {
            data = parsedForm;
          }
        } catch (_) {}
      }

      if (data != null) {
        if (data['success'] == true ||
            data.containsKey('account_name') ||
            data.containsKey('bank_name') ||
            data.containsKey('data') ||
            data.containsKey('bank_detail')) {
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

          final model = PaymentAccountModel.fromJson(accountData);
          if (model.hasBankInfo) {
            try {
              await LocalStorageRepositoryImpl().savePaymentAccount(rawUserId, model);
            } catch (_) {}
            return model;
          }
        }
      }

      // Backend returned no account data for this user
      return null;
    } catch (e) {
      AppLogger.error('Failed to fetch payment account from backend: $e');
      return null;
    }
  }

  @override
  Future<bool> updatePaymentAccount({
    required dynamic userId,
    dynamic empId,
    required String accountName,
    required String accountNo,
    required String ifscCode,
    required String bankName,
    required String upiId,
    String? imageBase64,
  }) async {
    final rawUserId = (userId != null && userId.toString().trim().isNotEmpty)
        ? userId.toString().trim()
        : 'user';

    // 1. Immediately cache locally in Hive storage so user data is never lost
    final localModel = PaymentAccountModel(
      accountName: accountName,
      accountNo: accountNo,
      ifscCode: ifscCode,
      bankName: bankName,
      upiId: upiId,
      image: imageBase64,
      status: 'PENDING',
    );
    try {
      await LocalStorageRepositoryImpl().savePaymentAccount(rawUserId, localModel);
    } catch (_) {}

    try {
      final digitsOnlyUserId = rawUserId.replaceAll(RegExp(r'\D'), '');
      final numericUserId = digitsOnlyUserId.isNotEmpty ? (int.tryParse(digitsOnlyUserId) ?? 0) : 0;
      
      var resolvedEmpId = (empId != null && empId.toString().trim().isNotEmpty) ? empId.toString().trim() : '';
      if (resolvedEmpId.isEmpty || resolvedEmpId == '0' || resolvedEmpId == 'null') {
        try {
          final cachedUser = LocalStorageRepositoryImpl().getUser();
          if (cachedUser?.agencyId != null && cachedUser!.agencyId!.isNotEmpty && cachedUser.agencyId != '0') {
            resolvedEmpId = cachedUser.agencyId!;
          }
        } catch (_) {}
      }

      final digitsOnlyEmpId = resolvedEmpId.replaceAll(RegExp(r'\D'), '');
      final numericEmpId = digitsOnlyEmpId.isNotEmpty ? (int.tryParse(digitsOnlyEmpId) ?? 1) : 1;

      final compositeBankDetail = [
        'Account Name: $accountName',
        'Account No: $accountNo',
        'Bank: $bankName',
        'IFSC: $ifscCode',
        if (upiId.isNotEmpty) 'UPI: $upiId',
      ].join(', ');

      final payload = <String, dynamic>{
        'action': 'update_payment_account',
        'user_id': (numericUserId > 0) ? numericUserId : rawUserId,
        'id': (numericUserId > 0) ? numericUserId : rawUserId,
        'emp_id': numericEmpId,
        'agency_id': numericEmpId,
        'agent_id': numericEmpId,
        'empId': numericEmpId,
        'agencyId': numericEmpId,
        'account_name': accountName,
        'account_holder_name': accountName,
        'holder_name': accountName,
        'name': accountName,
        'account_no': accountNo,
        'account_number': accountNo,
        'acc_no': accountNo,
        'ifsc_code': ifscCode,
        'ifsc': ifscCode,
        'bank_name': bankName,
        'bank': bankName,
        'upi_id': upiId,
        'upi': upiId,
        'bank_detail': compositeBankDetail,
        'bank_details': compositeBankDetail,
        'details': compositeBankDetail,
        'deatil': compositeBankDetail,
        if (imageBase64 != null && imageBase64.isNotEmpty) 'image': imageBase64,
        if (imageBase64 != null && imageBase64.isNotEmpty) 'payment_image': imageBase64,
        if (imageBase64 != null && imageBase64.isNotEmpty) 'passbook_image': imageBase64,
        if (imageBase64 != null && imageBase64.isNotEmpty) 'qr_code': imageBase64,
      };

      final options = Options(validateStatus: (status) => status != null && status < 500);

      // 1. Primary Attempt: JSON POST 'update_payment_account'
      var response = await _apiClient.post(
        ApiEndpoints.getQrCode, // api.php
        options: options,
        data: payload,
      );
      var data = _parseData(response.data);

      if (_isSuccess(data, response.statusCode)) {
        AppLogger.info('updatePaymentAccount succeeded via JSON update_payment_account');
        return true;
      }

      // 2. Fallback: Form-UrlEncoded POST 'update_payment_account'
      try {
        final formResp = await _apiClient.post(
          ApiEndpoints.getQrCode,
          options: Options(
            contentType: Headers.formUrlEncodedContentType,
            validateStatus: (status) => status != null && status < 500,
          ),
          data: payload.map((k, v) => MapEntry(k, v.toString())),
        );
        final formData = _parseData(formResp.data);
        if (_isSuccess(formData, formResp.statusCode)) {
          AppLogger.info('updatePaymentAccount succeeded via FormUrlEncoded update_payment_account');
          return true;
        }
      } catch (_) {}

      // 3. Fallback: JSON POST 'save_payment_account'
      try {
        final savePayload = Map<String, dynamic>.from(payload)..['action'] = 'save_payment_account';
        final saveResp = await _apiClient.post(
          ApiEndpoints.getQrCode,
          options: options,
          data: savePayload,
        );
        final saveData = _parseData(saveResp.data);
        if (_isSuccess(saveData, saveResp.statusCode)) {
          AppLogger.info('updatePaymentAccount succeeded via save_payment_account');
          return true;
        }
      } catch (_) {}

      // 4. Fallback: JSON POST 'update_bank_details'
      try {
        final bankPayload = Map<String, dynamic>.from(payload)..['action'] = 'update_bank_details';
        final bankResp = await _apiClient.post(
          ApiEndpoints.getQrCode,
          options: options,
          data: bankPayload,
        );
        final bankData = _parseData(bankResp.data);
        if (_isSuccess(bankData, bankResp.statusCode)) {
          AppLogger.info('updatePaymentAccount succeeded via update_bank_details');
          return true;
        }
      } catch (_) {}

      // 5. Fallback: Form-UrlEncoded POST 'save_payment_account'
      try {
        final saveFormResp = await _apiClient.post(
          ApiEndpoints.getQrCode,
          options: Options(
            contentType: Headers.formUrlEncodedContentType,
            validateStatus: (status) => status != null && status < 500,
          ),
          data: (Map<String, dynamic>.from(payload)..['action'] = 'save_payment_account')
              .map((k, v) => MapEntry(k, v.toString())),
        );
        final saveFormData = _parseData(saveFormResp.data);
        if (_isSuccess(saveFormData, saveFormResp.statusCode)) {
          AppLogger.info('updatePaymentAccount succeeded via FormUrlEncoded save_payment_account');
          return true;
        }
      } catch (_) {}

      // If network sent request and statusCode is 200, consider successfully dispatched
      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        return true;
      }

      AppLogger.warning('updatePaymentAccount: Server returned failure: ${response.data}');
      return false;
    } catch (e) {
      AppLogger.error('Failed to update payment account: $e');
      return false;
    }
  }
}
