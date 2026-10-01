import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/models/user/recharge_record_model.dart';
import 'package:user_app/utils/validators.dart';

void main() {
  group('Dual Approval Status Logic Tests', () {
    test('Single-stage AGENCY-APPROVED returns false (not fully approved)', () {
      expect(RechargeRecordModel.isRechargeFullyApproved('AGENCY-APPROVED'), isFalse);
      expect(RechargeRecordModel.isRechargeFullyApproved('AGENCY_APPROVED'), isFalse);
      expect(RechargeRecordModel.isRechargeFullyApproved('agency approved'), isFalse);
    });

    test('Single-stage EMPLOYEE-APPROVED returns false (not fully approved)', () {
      expect(RechargeRecordModel.isRechargeFullyApproved('EMPLOYEE-APPROVED'), isFalse);
      expect(RechargeRecordModel.isRechargeFullyApproved('EMP-APPROVED'), isFalse);
      expect(RechargeRecordModel.isRechargeFullyApproved('emp_approved'), isFalse);
    });

    test('Pending stage statuses return false', () {
      expect(RechargeRecordModel.isRechargeFullyApproved('EMPLOYEE-PENDING'), isFalse);
      expect(RechargeRecordModel.isRechargeFullyApproved('AGENCY-PENDING'), isFalse);
      expect(RechargeRecordModel.isRechargeFullyApproved('PENDING'), isFalse);
    });

    test('Rejected statuses return false', () {
      expect(RechargeRecordModel.isRechargeFullyApproved('REJECTED'), isFalse);
      expect(RechargeRecordModel.isRechargeFullyApproved('DECLINED'), isFalse);
      expect(RechargeRecordModel.isRechargeFullyApproved('FAILED'), isFalse);
    });

    test('Complete dual approval statuses return true', () {
      expect(RechargeRecordModel.isRechargeFullyApproved('SUCCESSFUL'), isTrue);
      expect(RechargeRecordModel.isRechargeFullyApproved('DONE'), isTrue);
      expect(RechargeRecordModel.isRechargeFullyApproved('COMPLETED'), isTrue);
      expect(RechargeRecordModel.isRechargeFullyApproved('BOTH-APPROVED'), isTrue);
      expect(RechargeRecordModel.isRechargeFullyApproved('FULLY-APPROVED'), isTrue);
      expect(RechargeRecordModel.isRechargeFullyApproved('APPROVED'), isTrue);
      expect(RechargeRecordModel.isRechargeFullyApproved('AGENCY-APPROVED, EMPLOYEE-APPROVED'), isTrue);
    });
  });

  group('Transaction ID / UTR Validation Tests (No Length Limit)', () {
    test('Null or empty Transaction ID fails validation', () {
      expect(Validators.validateTxnId(null), equals('Transaction ID / UTR is required'));
      expect(Validators.validateTxnId(''), equals('Transaction ID / UTR is required'));
      expect(Validators.validateTxnId('   '), equals('Transaction ID / UTR is required'));
    });

    test('Any non-empty Transaction ID passes validation without length limit', () {
      expect(Validators.validateTxnId('12345'), isNull);
      expect(Validators.validateTxnId('123456789012'), isNull);
      expect(Validators.validateTxnId('TXN987654321098'), isNull);
      expect(Validators.validateTxnId('IMPS123456789012345678'), isNull);
    });
  });
}
