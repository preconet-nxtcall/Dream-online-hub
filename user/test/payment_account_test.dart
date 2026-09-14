import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/models/user/payment_account_model.dart';
import 'package:user_app/repositories/payment_account_repository.dart';
import 'package:user_app/features/profile/presentation/widgets/payment_account_widget.dart';

class MockPaymentAccountRepository implements PaymentAccountRepository {
  PaymentAccountModel? accountToReturn;
  bool updateResultToReturn = true;

  dynamic lastFetchedUserId;
  dynamic lastUpdatedUserId;
  String? lastUpdatedAccountName;
  String? lastUpdatedAccountNo;
  String? lastUpdatedIfscCode;
  String? lastUpdatedBankName;
  String? lastUpdatedUpiId;
  String? lastUpdatedImageBase64;

  @override
  Future<PaymentAccountModel?> getPaymentAccount(dynamic userId) async {
    lastFetchedUserId = userId;
    return accountToReturn;
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
    lastUpdatedUserId = userId;
    lastUpdatedAccountName = accountName;
    lastUpdatedAccountNo = accountNo;
    lastUpdatedIfscCode = ifscCode;
    lastUpdatedBankName = bankName;
    lastUpdatedUpiId = upiId;
    lastUpdatedImageBase64 = imageBase64;
    return updateResultToReturn;
  }
}

void main() {
  group('PaymentAccountModel Unit Tests', () {
    test('PaymentAccountModel fromJson parses standard keys correctly', () {
      final jsonMap = {
        'account_name': 'John Doe',
        'account_no': '9876543210',
        'ifsc_code': 'SBIN0001234',
        'bank_name': 'State Bank of India',
        'upi_id': 'john@upi',
        'image': 'data:image/png;base64,samplebase64data',
      };

      final model = PaymentAccountModel.fromJson(jsonMap);

      expect(model.accountName, equals('John Doe'));
      expect(model.accountNo, equals('9876543210'));
      expect(model.ifscCode, equals('SBIN0001234'));
      expect(model.bankName, equals('State Bank of India'));
      expect(model.upiId, equals('john@upi'));
      expect(model.image, equals('data:image/png;base64,samplebase64data'));
    });

    test('PaymentAccountModel fromJson supports fallback key variations', () {
      final jsonMap = {
        'accountHolderName': 'Alice Smith',
        'accountNumber': '555444333',
        'ifsc': 'HDFC0004321',
        'bankName': 'HDFC Bank',
        'upiId': 'alice@hdfc',
        'passbook_image': 'https://example.com/passbook.png',
      };

      final model = PaymentAccountModel.fromJson(jsonMap);

      expect(model.accountName, equals('Alice Smith'));
      expect(model.accountNo, equals('555444333'));
      expect(model.ifscCode, equals('HDFC0004321'));
      expect(model.bankName, equals('HDFC Bank'));
      expect(model.upiId, equals('alice@hdfc'));
      expect(model.image, equals('https://example.com/passbook.png'));
    });

    test('PaymentAccountModel toJson serializes correctly', () {
      const model = PaymentAccountModel(
        accountName: 'Bob Builder',
        accountNo: '1122334455',
        ifscCode: 'ICIC0009999',
        bankName: 'ICICI Bank',
        upiId: 'bob@icici',
        image: 'data:image/jpeg;base64,xyz123',
      );

      final jsonMap = model.toJson();

      expect(jsonMap['account_name'], equals('Bob Builder'));
      expect(jsonMap['account_no'], equals('1122334455'));
      expect(jsonMap['ifsc_code'], equals('ICIC0009999'));
      expect(jsonMap['bank_name'], equals('ICICI Bank'));
      expect(jsonMap['upi_id'], equals('bob@icici'));
      expect(jsonMap['image'], equals('data:image/jpeg;base64,xyz123'));
    });

    test('PaymentAccountModel parses status and computes isPendingApproval correctly', () {
      final pendingModel = PaymentAccountModel.fromJson({'status': 'pending'});
      final approvedModel = PaymentAccountModel.fromJson({'status': 'approved'});
      final readStatusPendingModel = PaymentAccountModel.fromJson({'read_status': 'PENDING'});

      expect(pendingModel.isPendingApproval, isTrue);
      expect(approvedModel.isPendingApproval, isFalse);
      expect(readStatusPendingModel.isPendingApproval, isTrue);
    });

    test('PaymentAccountModel parses get_qr_code response with bank_detail and qr_image_url', () {
      final qrResponse = {
        'success': true,
        'qr_available': true,
        'qr_image_url': 'http://example.com/qr.png',
        'qr_id': 1,
        'range_id': 2,
        'emp_id': 3,
        'bank_id': 4,
        'bank_name': 'State Bank of India',
        'bank_detail': 'Account Name: John Doe, IFSC: SBIN0001234',
      };

      final model = PaymentAccountModel.fromJson(qrResponse);

      expect(model.accountName, equals('John Doe'));
      expect(model.ifscCode, equals('SBIN0001234'));
      expect(model.bankName, equals('State Bank of India'));
      expect(model.image, equals('http://example.com/qr.png'));
    });
  });

  group('PaymentAccountWidget Widget Tests', () {
    late MockPaymentAccountRepository mockRepo;

    setUp(() {
      mockRepo = MockPaymentAccountRepository();
    });

    testWidgets('Renders all fields, labels, and Save Payment Account button', (WidgetTester tester) async {
      mockRepo.accountToReturn = const PaymentAccountModel(
        accountName: 'DreamHub User',
        accountNo: '1234567890',
        ifscCode: 'IFSC0001',
        bankName: 'SBI Bank',
        upiId: 'dreamhub@upi',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(splashFactory: NoSplash.splashFactory),
          home: Scaffold(
            body: SingleChildScrollView(
              child: PaymentAccountWidget(repository: mockRepo, userId: 'user_123', isReadOnly: true),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Title & Labels are rendered
      expect(find.text('Payment Account Details'), findsOneWidget);
      expect(find.text('ACCOUNT HOLDER NAME'), findsOneWidget);
      expect(find.text('ACCOUNT NUMBER'), findsOneWidget);
      expect(find.text('BANK NAME'), findsOneWidget);
      expect(find.text('IFSC CODE'), findsOneWidget);
      expect(find.text('UPI ID'), findsOneWidget);
      expect(find.text('QR CODE / PASSBOOK IMAGE'), findsOneWidget);
      expect(find.text('Choose File'), findsOneWidget);
      expect(find.text('Close Details'), findsOneWidget);

      // Verify prefilled field values
      expect(find.text('DreamHub User'), findsOneWidget);
      expect(find.text('1234567890'), findsOneWidget);
      expect(find.text('SBI Bank'), findsOneWidget);
      expect(find.text('IFSC0001'), findsOneWidget);
      expect(find.text('dreamhub@upi'), findsOneWidget);
    });

    testWidgets('Triggers updatePaymentAccount repository call on Save Payment Account click', (WidgetTester tester) async {
      mockRepo.accountToReturn = const PaymentAccountModel(
        accountName: 'Initial Name',
        accountNo: '11111111',
        ifscCode: 'IFSC123',
        bankName: 'Axis Bank',
        upiId: 'user@axis',
        image: 'https://dreamonlinehub.club/uploads/photo.png',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(splashFactory: NoSplash.splashFactory),
          home: Scaffold(
            body: SingleChildScrollView(
              child: PaymentAccountWidget(repository: mockRepo, userId: 'user_123'),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap the Save Payment Account button
      final saveBtn = find.text('Save Payment Account');
      expect(saveBtn, findsOneWidget);
      await tester.tap(saveBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify mock repo received updated field values
      expect(mockRepo.lastUpdatedAccountName, equals('Initial Name'));
      expect(mockRepo.lastUpdatedAccountNo, equals('11111111'));
      expect(mockRepo.lastUpdatedIfscCode, equals('IFSC123'));
      expect(mockRepo.lastUpdatedBankName, equals('Axis Bank'));
      expect(mockRepo.lastUpdatedUpiId, equals('user@axis'));
    });

    testWidgets('Shows pending message and prevents repo call when approval is pending', (WidgetTester tester) async {
      mockRepo.accountToReturn = const PaymentAccountModel(
        accountName: 'Pending User',
        accountNo: '9999999999',
        ifscCode: 'IFSC999',
        bankName: 'HDFC Bank',
        upiId: 'pending@upi',
        image: 'https://dreamonlinehub.club/uploads/photo.png',
        status: 'pending',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(splashFactory: NoSplash.splashFactory),
          home: Scaffold(
            body: SingleChildScrollView(
              child: PaymentAccountWidget(repository: mockRepo, userId: 'user_123', isPendingApproval: true),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify warning message banner and badge are displayed
      expect(find.text('You cannot update your payment account detail while approval is pending.'), findsOneWidget);
      expect(find.text('PENDING APPROVAL'), findsOneWidget);

      // Tap Save Payment Account button
      final saveBtn = find.text('Save Payment Account');
      expect(saveBtn, findsOneWidget);
      await tester.tap(saveBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify mockRepo update was NOT called
      expect(mockRepo.lastUpdatedAccountName, isNull);
    });

    testWidgets('user@gmail.com test: verifies pending approval restriction message on payment account update attempt', (WidgetTester tester) async {
      mockRepo.accountToReturn = const PaymentAccountModel(
        accountName: 'Test User',
        accountNo: '987654321',
        ifscCode: 'HDFC000123',
        bankName: 'HDFC Bank',
        upiId: 'user@gmail.com',
        image: 'https://dreamonlinehub.club/uploads/user_qr.png',
        status: 'pending',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(splashFactory: NoSplash.splashFactory),
          home: Scaffold(
            body: SingleChildScrollView(
              child: PaymentAccountWidget(
                repository: mockRepo,
                userId: 'user@gmail.com',
                isPendingApproval: true,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 1. Verify warning banner text
      expect(find.text('You cannot update your payment account detail while approval is pending.'), findsOneWidget);

      // 2. Verify PENDING APPROVAL badge
      expect(find.text('PENDING APPROVAL'), findsOneWidget);

      // 3. Attempt to click "Save Payment Account"
      final saveButton = find.text('Save Payment Account');
      expect(saveButton, findsOneWidget);
      await tester.tap(saveButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 4. Verify no backend update was dispatched for user@gmail.com
      expect(mockRepo.lastUpdatedAccountName, isNull);
      expect(mockRepo.lastUpdatedUserId, isNull);
    });
  });
}
