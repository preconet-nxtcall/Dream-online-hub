import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agency_app/models/user/recharge_record_model.dart';
import 'package:agency_app/features/agency_dashboard/presentation/widgets/approved_recharge_widget.dart';

void main() {
  group('ApprovedRechargeWidget Logic Tests', () {
    const pendingRecord = RechargeRecordModel(
      id: '#101',
      bookName: 'Lucky Book',
      userName: 'Client A',
      transactionDetails: 'UTR123456789',
      amount: 500.0,
      status: 'AGENCY-PENDING',
      date: '2026-08-29 12:00',
    );

    const approvedRecord = RechargeRecordModel(
      id: '#102',
      bookName: 'Lucky Book',
      userName: 'Client B',
      transactionDetails: 'UTR987654321',
      amount: 1000.0,
      status: 'AGENCY-DONE',
      date: '2026-08-29 12:05',
    );

    const numericIdRecord = RechargeRecordModel(
      id: '103',
      bookName: 'Lucky Book',
      userName: 'Client C',
      transactionDetails: 'UTR555555555',
      amount: 1500.0,
      status: 'AGENCY-PENDING',
      date: '2026-08-29 12:10',
    );

    final testTheme = ThemeData(
      useMaterial3: false,
      splashFactory: NoSplash.splashFactory,
    );

    testWidgets('Renders widget with initial records correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: testTheme,
          home: const Scaffold(
            body: ApprovedRechargeWidget(
              initialRecords: [pendingRecord, approvedRecord, numericIdRecord],
            ),
          ),
        ),
      );
      await tester.pump();

      // Check column headers exist
      expect(find.text('ID'), findsOneWidget);
      expect(find.text('TRANSACTION DETAILS'), findsOneWidget);
      expect(find.text('STATUS & DATE'), findsOneWidget);
      expect(find.text('ACTIONS'), findsOneWidget);

      // Check records rendered
      expect(find.text('#101'), findsOneWidget);
      expect(find.text('#102'), findsOneWidget);
      expect(find.text('103'), findsOneWidget);

      // Check Authority Not Verified Yet text is visible for AGENCY-DONE
      expect(find.text('Authority Not Verified Yet.'), findsOneWidget);
    });

    testWidgets('APPROVE RECHARGE button IS VISIBLE for AGENCY-PENDING record', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: testTheme,
          home: const Scaffold(
            body: ApprovedRechargeWidget(
              initialRecords: [pendingRecord],
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('View'));
      await tester.pump();

      expect(find.text('Check Request Details'), findsOneWidget);
      expect(find.text('APPROVE RECHARGE'), findsOneWidget);
    });

    testWidgets('APPROVE RECHARGE button IS HIDDEN for AGENCY-DONE record', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: testTheme,
          home: const Scaffold(
            body: ApprovedRechargeWidget(
              initialRecords: [approvedRecord],
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('View'));
      await tester.pump();

      expect(find.text('Check Request Details'), findsOneWidget);
      expect(find.text('APPROVE RECHARGE'), findsNothing);
    });
  });
}
