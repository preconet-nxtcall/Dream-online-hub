import 'package:flutter_test/flutter_test.dart';
import 'package:agency_app/models/user/recharge_record_model.dart';
import 'package:agency_app/providers/employee_provider.dart';
import 'package:agency_app/repositories/employee_repository.dart';

class MockWorkflowRepository implements EmployeeRepository {
  List<RechargeRecordModel> recharges = [];
  List<RechargeRecordModel> withdrawals = [];

  @override
  Future<List<RechargeRecordModel>> fetchRechargeRecords({String statusType = 'all'}) async {
    return List.from(recharges);
  }

  @override
  Future<List<RechargeRecordModel>> fetchWithdrawalRecords({String statusType = 'all'}) async {
    return List.from(withdrawals);
  }

  @override
  Future<bool> verifyRecharge({
    required String id,
    required String status,
    required String remark,
    String? transactionId,
  }) async {
    final idx = recharges.indexWhere((r) => r.id == id || r.id.replaceAll(RegExp(r'\D'), '') == id.replaceAll(RegExp(r'\D'), ''));
    if (idx != -1) {
      recharges[idx] = RechargeRecordModel(
        id: recharges[idx].id,
        bookName: recharges[idx].bookName,
        userName: recharges[idx].userName,
        transactionDetails: transactionId ?? recharges[idx].transactionDetails,
        amount: recharges[idx].amount,
        status: status,
        date: recharges[idx].date,
        agencyId: recharges[idx].agencyId,
        empId: recharges[idx].empId,
      );
    }
    return true;
  }

  @override
  Future<bool> verifyWithdrawal({
    required String id,
    required String status,
    required String remark,
    String? transactionId,
  }) async {
    final idx = withdrawals.indexWhere((w) => w.id == id || w.id.replaceAll(RegExp(r'\D'), '') == id.replaceAll(RegExp(r'\D'), ''));
    if (idx != -1) {
      withdrawals[idx] = RechargeRecordModel(
        id: withdrawals[idx].id,
        bookName: withdrawals[idx].bookName,
        userName: withdrawals[idx].userName,
        transactionDetails: transactionId ?? withdrawals[idx].transactionDetails,
        amount: withdrawals[idx].amount,
        status: status,
        date: withdrawals[idx].date,
        agencyId: withdrawals[idx].agencyId,
        empId: withdrawals[idx].empId,
        accountHolderName: withdrawals[idx].accountHolderName,
        accountNumber: withdrawals[idx].accountNumber,
        bankName: withdrawals[idx].bankName,
        ifscCode: withdrawals[idx].ifscCode,
        upiId: withdrawals[idx].upiId,
      );
    }
    return true;
  }
}

void main() {
  group('Two-Step Approval & Verification Workflow Tests', () {
    late MockWorkflowRepository repo;
    late EmployeeProvider employeeProvider;

    setUp(() {
      repo = MockWorkflowRepository();
      repo.recharges = [
        const RechargeRecordModel(
          id: '#101',
          bookName: 'Gold Book',
          userName: 'Alice',
          transactionDetails: 'TXN101',
          amount: 5000.0,
          status: 'AGENCY-PENDING',
          date: '2026-10-10',
          agencyId: '3',
          empId: '3',
        ),
      ];

      repo.withdrawals = [
        const RechargeRecordModel(
          id: '#201',
          bookName: 'Platinum Book',
          userName: 'Bob',
          transactionDetails: 'Bank Transfer',
          amount: 2500.0,
          status: 'EMPLOYEE-PASS',
          date: '2026-10-10',
          agencyId: '3',
          empId: '3',
          accountHolderName: 'Bob Builder',
          accountNumber: '987654321012',
          bankName: 'HDFC Bank',
          ifscCode: 'HDFC0001234',
          upiId: 'bob@upi',
        ),
      ];

      employeeProvider = EmployeeProvider(repository: repo);
      employeeProvider.setAgencyId('3');
    });

    test('1. Recharge: One-Time Approval (AGENCY-DONE or EMPLOYEE-DONE) Completes and Locks Request', () async {
      await employeeProvider.refreshAll();

      // Initially, Recharge #101 is AGENCY-PENDING
      expect(employeeProvider.pendingRechargesCount, 1);
      expect(employeeProvider.successfulRechargesCount, 0);

      // When approved (by Agency or Employee), status becomes 'AGENCY-DONE' (or 'EMPLOYEE-DONE')
      repo.recharges[0] = RechargeRecordModel(
        id: repo.recharges[0].id,
        bookName: repo.recharges[0].bookName,
        userName: repo.recharges[0].userName,
        transactionDetails: repo.recharges[0].transactionDetails,
        amount: repo.recharges[0].amount,
        status: 'AGENCY-DONE',
        date: repo.recharges[0].date,
        agencyId: repo.recharges[0].agencyId,
        empId: repo.recharges[0].empId,
      );

      await employeeProvider.refreshAll();

      // FINAL STATE: Now it is officially Approved / Successful and locked from further edits!
      expect(employeeProvider.pendingRechargesCount, 0);
      expect(employeeProvider.successfulRechargesCount, 1);
      expect(employeeProvider.agencyScopedRecharges.first.status, 'AGENCY-DONE');
    });

    test('2. Withdrawal: Passed to Agency (EMPLOYEE-PASS) -> Agency Completes Payout', () async {
      await employeeProvider.refreshAll();

      // Initially, Withdrawal #201 is EMPLOYEE-PASS (waiting for payout)
      expect(employeeProvider.pendingWithdrawalsCount, 1);
      expect(employeeProvider.successfulWithdrawalsCount, 0);

      // Step 2: Agency Processes Withdrawal -> marks 'AGENCY-DONE'
      repo.withdrawals[0] = RechargeRecordModel(
        id: repo.withdrawals[0].id,
        bookName: repo.withdrawals[0].bookName,
        userName: repo.withdrawals[0].userName,
        transactionDetails: 'UTR99887766',
        amount: repo.withdrawals[0].amount,
        status: 'AGENCY-DONE',
        date: repo.withdrawals[0].date,
        agencyId: repo.withdrawals[0].agencyId,
        empId: repo.withdrawals[0].empId,
        accountHolderName: repo.withdrawals[0].accountHolderName,
        accountNumber: repo.withdrawals[0].accountNumber,
        bankName: repo.withdrawals[0].bankName,
        ifscCode: repo.withdrawals[0].ifscCode,
        upiId: repo.withdrawals[0].upiId,
      );

      await employeeProvider.refreshAll();

      // FINAL STATE: Payout is completed and successful
      expect(employeeProvider.pendingWithdrawalsCount, 0);
      expect(employeeProvider.successfulWithdrawalsCount, 1);
      expect(employeeProvider.agencyScopedWithdrawals.first.status, 'AGENCY-DONE');
    });

    test('3. Rejections properly update counts and isolate states', () async {
      repo.recharges = [
        const RechargeRecordModel(
          id: '#102',
          bookName: 'Silver Book',
          userName: 'Charlie',
          transactionDetails: 'TXN102',
          amount: 1000.0,
          status: 'EMPLOYEE-REJECT',
          date: '2026-10-10',
          agencyId: '3',
          empId: '3',
        ),
      ];

      await employeeProvider.refreshAll();

      expect(employeeProvider.rejectedRechargesCount, 1);
      expect(employeeProvider.pendingRechargesCount, 0);
      expect(employeeProvider.successfulRechargesCount, 0);
    });
  });
}
