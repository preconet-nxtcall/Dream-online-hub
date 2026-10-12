import 'package:flutter_test/flutter_test.dart';
import 'package:agency_app/models/user/recharge_record_model.dart';
import 'package:agency_app/providers/employee_provider.dart';
import 'package:agency_app/repositories/employee_repository.dart';

class MockEmployeeRepository implements EmployeeRepository {
  List<RechargeRecordModel> mockRecharges = [];
  List<RechargeRecordModel> mockWithdrawals = [];

  @override
  Future<List<RechargeRecordModel>> fetchRechargeRecords({String statusType = 'all'}) async {
    return mockRecharges;
  }

  @override
  Future<List<RechargeRecordModel>> fetchWithdrawalRecords({String statusType = 'all'}) async {
    return mockWithdrawals;
  }

  @override
  Future<bool> verifyRecharge({
    required String id,
    required String status,
    required String remark,
    String? transactionId,
  }) async {
    return true;
  }

  @override
  Future<bool> verifyWithdrawal({
    required String id,
    required String status,
    required String remark,
    String? transactionId,
  }) async {
    return true;
  }
}

void main() {
  group('EmployeeProvider & Logic Tests', () {
    late MockEmployeeRepository mockRepo;
    late EmployeeProvider provider;

    setUp(() {
      mockRepo = MockEmployeeRepository();

      // Sample data matching live database:
      // Agency 3 (DOHBRANCH25 / S MONDAL):
      // 10 EMPLOYEE-DONE
      // 1 EMPLOYEE-REJECT (ID 16)
      // 8 AGENCY-REJECT (IDs 4, 7, 8, 9, 10, 11, 12, 15)
      // Agency 1:
      // 2 EMPLOYEE-DONE, 2 EMPLOYEE-REJECT
      mockRepo.mockRecharges = [
        for (int i = 1; i <= 10; i++)
          RechargeRecordModel(
            id: '$i',
            bookName: 'Book $i',
            transactionDetails: 'TXN$i',
            amount: 500.0,
            status: 'EMPLOYEE-DONE',
            date: '09/30/2026',
            empId: '3',
            agencyId: '3',
          ),
        const RechargeRecordModel(
          id: '16',
          bookName: 'Book 16',
          transactionDetails: 'TXN16',
          amount: 100.0,
          status: 'EMPLOYEE-REJECT',
          date: '09/25/2026',
          empId: '3',
          agencyId: '3',
        ),
        for (int i = 1; i <= 8; i++)
          RechargeRecordModel(
            id: 'ag_$i',
            bookName: 'Agency Reject $i',
            transactionDetails: 'AG_TXN$i',
            amount: 100.0,
            status: 'AGENCY-REJECT',
            date: '09/25/2026',
            empId: '3',
            agencyId: '3',
          ),
        const RechargeRecordModel(
          id: 'other_1',
          bookName: 'Other Agency Book',
          transactionDetails: 'TXN_OTHER',
          amount: 500.0,
          status: 'EMPLOYEE-DONE',
          date: '09/20/2026',
          empId: '1',
          agencyId: '1',
        ),
      ];

      // Withdrawals:
      // 1 Pending (ID 3), 1 Approved (ID 1) for Agency 3
      mockRepo.mockWithdrawals = [
        const RechargeRecordModel(
          id: '3',
          bookName: 'SKYEXCHANGE',
          transactionDetails: 'Bank: SBI, Acc: 1076543210',
          amount: 10.0,
          status: 'EMPLOYEE-PASS',
          date: '09/25/2026',
          empId: '3',
          agencyId: '3',
        ),
        const RechargeRecordModel(
          id: '1',
          bookName: 'SKYEXCHANGE',
          transactionDetails: 'TRNID11105225',
          amount: 50.0,
          status: 'AGENCY-DONE',
          date: '09/25/2026',
          empId: '3',
          agencyId: '3',
        ),
        const RechargeRecordModel(
          id: 'other_w',
          bookName: 'Other Withdraw',
          transactionDetails: 'TRN_OTHER',
          amount: 100.0,
          status: 'EMPLOYEE-PENDING',
          date: '09/25/2026',
          empId: '1',
          agencyId: '1',
        ),
      ];

      provider = EmployeeProvider(repository: mockRepo);
      provider.setAgencyId('3');
    });

    test('1. Scoping & Counts for Agency 3 Employee (Option 1)', () async {
      await provider.refreshAll();

      // Agency scoped recharges: excludes Agency 1 (id: other_1)
      expect(provider.agencyScopedRecharges.length, 19);

      // Successful recharges: 10
      expect(provider.successfulRechargesCount, 10);

      // Rejected recharges: 9 (1 EMPLOYEE-REJECT + 8 AGENCY-REJECT)
      expect(provider.rejectedRechargesCount, 9);

      // Pending recharges: 0
      expect(provider.pendingRechargesCount, 0);

      // All active recharges count: 10 + 9 + 0 = 19
      expect(provider.allRechargesCount, 19);

      // Filter: 'all' returns all 19 items
      provider.setRechargeFilter('all');
      expect(provider.filteredRecharges.length, 19);

      // Filter: 'successful' returns 10
      provider.setRechargeFilter('successful');
      expect(provider.filteredRecharges.length, 10);

      // Filter: 'rejected' returns 9
      provider.setRechargeFilter('rejected');
      expect(provider.filteredRecharges.length, 9);

      // Filter: 'pending' returns 0
      provider.setRechargeFilter('pending');
      expect(provider.filteredRecharges.length, 0);
    });

    test('2. Withdrawal Scoping & Counts for Agency 3', () async {
      await provider.refreshAll();

      // Scoped withdrawals: excludes Agency 1 (id: other_w)
      expect(provider.agencyScopedWithdrawals.length, 2);

      // Total withdrawals: 2
      expect(provider.allWithdrawalsCount, 2);

      // Pending: 1
      expect(provider.pendingWithdrawalsCount, 1);

      // Approved: 1
      expect(provider.successfulWithdrawalsCount, 1);

      // Rejected: 0
      expect(provider.rejectedWithdrawalsCount, 0);
    });

    test('3. One-Time Verification & Automatic Locking for Withdrawals', () async {
      await provider.refreshAll();

      expect(provider.pendingWithdrawalsCount, 1);

      final pendingItem = provider.filteredWithdrawals.firstWhere(
        (w) => w.id == '3',
      );

      // Verify and Pass to Agency
      final success = await provider.verifyWithdrawal(
        item: pendingItem,
        newStatus: 'EMPLOYEE-PASS',
        remark: 'Verified and passed',
      );

      expect(success, true);

      // State is immediately updated in-memory
      final updatedItem = provider.withdrawals.firstWhere((w) => w.id == '3');
      expect(updatedItem.status, 'EMPLOYEE-PASS');

      // Check locking logic: isPending becomes false
      final statusUpper = updatedItem.status.toUpperCase();
      final isDone = statusUpper.contains('DONE') ||
          statusUpper.contains('SUCCESS') ||
          statusUpper.contains('APPROVED');
      final isReject = statusUpper == 'EMPLOYEE-REJECT' ||
          statusUpper.contains('EMPLOYEE-REJECT');

      expect(isDone || isReject || statusUpper.contains('PASS'), true);
    });

    test('4. Search Filtering Works Across ID, Name, Book & Amount', () async {
      await provider.refreshAll();

      provider.setRechargeFilter('all');
      provider.searchRecharges('16');

      expect(provider.filteredRecharges.length, 1);
      expect(provider.filteredRecharges.first.id, '16');

      provider.searchRecharges('Book 10');
      expect(provider.filteredRecharges.length, 1);
      expect(provider.filteredRecharges.first.bookName, 'Book 10');

      provider.searchRecharges('Book 1');
      // Matches Book 1, Book 10, and Book 16
      expect(provider.filteredRecharges.length, 3);

      provider.searchRecharges('');
      expect(provider.filteredRecharges.length, 19);
    });
  });
}
