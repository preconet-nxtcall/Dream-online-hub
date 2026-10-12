import '../core/constants/api_endpoints.dart';
import '../core/errors/exceptions.dart';
import '../models/user/recharge_record_model.dart';
import '../network/api_client.dart';
import '../utils/logger.dart';

abstract class EmployeeRepository {
  Future<List<RechargeRecordModel>> fetchRechargeRecords({String statusType = 'all'});
  Future<List<RechargeRecordModel>> fetchWithdrawalRecords({String statusType = 'all'});
  Future<bool> verifyRecharge({
    required String id,
    required String status,
    required String remark,
    String? transactionId,
  });
  Future<bool> verifyWithdrawal({
    required String id,
    required String status,
    required String remark,
    String? transactionId,
  });
}

class EmployeeRepositoryImpl implements EmployeeRepository {
  final ApiClient _apiClient;

  EmployeeRepositoryImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  @override
  Future<List<RechargeRecordModel>> fetchRechargeRecords({
    String statusType = 'all',
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.getQrCode,
        data: {
          'action': 'recharge_records',
          'status_type': statusType,
        },
      );

      final data = response.data;
      final List<RechargeRecordModel> records = [];

      if (data is Map<String, dynamic> &&
          (data['success'] == true || data['status'] == 'success' || data['data'] != null)) {
        final rawData = data['data'];
        final List listData = [];
        if (rawData is List) {
          listData.addAll(rawData);
        } else if (rawData is Map<String, dynamic>) {
          if (rawData['pending'] is List) listData.addAll(rawData['pending'] as List);
          if (rawData['successful'] is List) listData.addAll(rawData['successful'] as List);
          if (rawData['rejected'] is List) listData.addAll(rawData['rejected'] as List);
        } else if (data['recharges'] is List) {
          listData.addAll(data['recharges'] as List);
        }

        for (final item in listData) {
          if (item is Map<String, dynamic>) {
            records.add(RechargeRecordModel.fromJson(item));
          }
        }
      }

      return records;
    } catch (e) {
      AppLogger.error('EmployeeRepository fetchRechargeRecords error: $e');
      throw ServerException(message: 'Failed to fetch recharge records: $e');
    }
  }

  @override
  Future<List<RechargeRecordModel>> fetchWithdrawalRecords({
    String statusType = 'all',
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.getQrCode,
        data: {
          'action': 'withdraw_records',
          'status_type': statusType,
        },
      );

      final data = response.data;
      final List<RechargeRecordModel> records = [];

      if (data is Map<String, dynamic> &&
          (data['success'] == true || data['status'] == 'success' || data['data'] != null || data['withdrawals'] != null)) {
        final rawData = data['data'] ?? data['withdrawals'];
        final List listData = [];

        if (rawData is List) {
          listData.addAll(rawData);
        } else if (rawData is Map<String, dynamic>) {
          if (rawData['pending'] is List) listData.addAll(rawData['pending'] as List);
          if (rawData['successful'] is List) listData.addAll(rawData['successful'] as List);
          if (rawData['rejected'] is List) listData.addAll(rawData['rejected'] as List);
        }

        for (final item in listData) {
          if (item is Map<String, dynamic>) {
            final idStr = item['withdrawal_id']?.toString() ?? item['id']?.toString() ?? '#01';
            final formattedId = idStr.startsWith('#') ? idStr : '#$idStr';
            final amountVal = double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0;
            final stageStatus = item['stage_status']?.toString() ?? 'EMPLOYEE-PENDING';
            final bookName = item['book_name']?.toString() ?? 'Platform Book';
            final userName = item['user_name']?.toString() ?? item['name']?.toString() ?? 'Client';
            final formattedDate = item['formatted_date']?.toString() ?? item['date']?.toString() ?? 'Just now';

            final acHolder = item['user_ac_holder_name']?.toString() ?? '';
            final acNo = item['user_ac_number']?.toString() ?? '';
            final bankName = item['user_bank_name']?.toString() ?? '';
            final ifsc = item['user_bank_ifsc']?.toString() ?? '';
            final upi = item['user_upi_id']?.toString() ?? '';

            final detailSummary = [
              if (acHolder.isNotEmpty) 'A/C: $acHolder',
              if (acNo.isNotEmpty) 'No: $acNo',
              if (bankName.isNotEmpty) 'Bank: $bankName',
              if (ifsc.isNotEmpty) 'IFSC: $ifsc',
              if (upi.isNotEmpty) 'UPI: $upi',
            ].join(' | ');

            records.add(
              RechargeRecordModel(
                id: formattedId,
                bookName: bookName,
                userName: userName,
                transactionDetails: detailSummary.isNotEmpty
                    ? detailSummary
                    : (item['deatil']?.toString() ?? item['transaction_id']?.toString() ?? 'Withdrawal Request'),
                amount: amountVal,
                status: stageStatus,
                date: formattedDate,
                imageUrl: item['image_url']?.toString() ?? item['image']?.toString(),
                invoiceUrl: item['emp_agency_image_url']?.toString() ?? item['emp_agency_image']?.toString(),
                agencyId: item['agency_id']?.toString(),
                empId: item['emp_id']?.toString(),
                accountHolderName: acHolder.isNotEmpty ? acHolder : null,
                accountNumber: acNo.isNotEmpty ? acNo : null,
                bankName: bankName.isNotEmpty ? bankName : null,
                ifscCode: ifsc.isNotEmpty ? ifsc : null,
                upiId: upi.isNotEmpty ? upi : null,
                userId: item['user_id']?.toString() ?? item['userId']?.toString(),
              ),
            );
          }
        }
      }

      return records;
    } catch (e) {
      AppLogger.error('EmployeeRepository fetchWithdrawalRecords error: $e');
      throw ServerException(message: 'Failed to fetch withdrawal records: $e');
    }
  }

  @override
  Future<bool> verifyRecharge({
    required String id,
    required String status,
    required String remark,
    String? transactionId,
  }) async {
    try {
      final rawId = id.replaceAll(RegExp(r'\D'), '');
      final isSuccess = status == 'EMPLOYEE-DONE' || status == 'AGENCY-DONE' || status == 'successful' || status == 'APPROVED';
      final isReject = status.contains('REJECT') || status.contains('FAIL');
      final dbStatus = isSuccess ? 'successful' : (isReject ? 'rejected' : 'pending');

      final payload = {
        'action': 'edit_recharge',
        'edit_recharge': 1,
        'edit_emp_recharge_pending': 1,
        'id': rawId,
        'status': dbStatus,
        'stage_status': status,
        'employee_remark': remark,
        'remark': remark,
        if (transactionId != null && transactionId.isNotEmpty)
          'transection_id': transactionId,
      };

      await _apiClient.post(
        ApiEndpoints.getQrCode,
        data: payload,
      );

      return true;
    } catch (e) {
      AppLogger.error('EmployeeRepository verifyRecharge error: $e');
      throw ServerException(message: 'Failed to verify recharge: $e');
    }
  }

  @override
  Future<bool> verifyWithdrawal({
    required String id,
    required String status,
    required String remark,
    String? transactionId,
  }) async {
    try {
      final rawId = id.replaceAll(RegExp(r'\D'), '');
      final isSuccess = status == 'AGENCY-DONE' || status == 'EMPLOYEE-DONE';
      final isReject = status.contains('REJECT') || status.contains('FAIL');
      final dbStatus = isSuccess ? 'successful' : (isReject ? 'rejected' : 'pending');

      final payload = {
        'action': 'edit_agency_withdraw_pending',
        'edit_agency_withdraw_pending': 1,
        'edit_emp_withdraw_pending': 1,
        'edit_withdraw': 1,
        'id': rawId,
        'status': dbStatus,
        'stage_status': status,
        'employee_remark': remark,
        'remark': remark,
        if (transactionId != null && transactionId.isNotEmpty)
          'transaction_id': transactionId,
      };

      await _apiClient.post(
        ApiEndpoints.getQrCode,
        data: payload,
      );

      return true;
    } catch (e) {
      AppLogger.error('EmployeeRepository verifyWithdrawal error: $e');
      throw ServerException(message: 'Failed to verify withdrawal: $e');
    }
  }
}
