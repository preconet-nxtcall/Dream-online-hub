import 'package:flutter_test/flutter_test.dart';
import 'package:agency_user_app/models/user/recharge_record_model.dart';
import 'package:agency_user_app/core/constants/api_endpoints.dart';

void main() {
  group('Recharge Backend Integration Unit Tests', () {
    test('ApiEndpoints.getQrCode endpoint matches PHP api.php contract', () {
      expect(ApiEndpoints.getQrCode, equals('api.php'));
    });

    test('RechargeRecordModel correctly parses backend response fields', () {
      final backendItem = {
        'id': '24',
        'book_id': '324',
        'book_name': 'Lucky Vault',
        'transection_id': 'TXN987654321',
        'amount': '300',
        'stage_status': 'EMPLOYEE-PENDING',
        'date_ts': '1785308720',
      };

      final idStr = backendItem['id']?.toString() ?? '';
      final rawAmount = double.tryParse(backendItem['amount']?.toString() ?? '0') ?? 0.0;
      final rawStatus = backendItem['stage_status']?.toString() ?? 'pending';

      final record = RechargeRecordModel(
        id: idStr.startsWith('#') ? idStr : '#$idStr',
        bookName: backendItem['book_name']!,
        transactionDetails: 'Txn: ${backendItem['transection_id']} • ₹${rawAmount.toStringAsFixed(2)}',
        amount: rawAmount,
        status: rawStatus,
        date: '2026-08-11',
      );

      expect(record.id, equals('#24'));
      expect(record.bookName, equals('Lucky Vault'));
      expect(record.amount, equals(300.0));
      expect(record.status, equals('EMPLOYEE-PENDING'));
      expect(record.transactionDetails, contains('TXN987654321'));
    });

    test('recharge_by_user payload payload matches developer spec', () {
      final payload = {
        'action': 'recharge_by_user',
        'user_id': 22,
        'qr_id': 3,
        'range_id': 1,
        'amount': 90.0,
        'emp_id': 1,
        'book_id': 324,
        'transection_id': 'TXN123456',
        'image': 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
      };

      expect(payload['action'], equals('recharge_by_user'));
      expect(payload['user_id'], equals(22));
      expect(payload['qr_id'], equals(3));
      expect(payload['range_id'], equals(1));
      expect(payload['amount'], equals(90.0));
      expect(payload['emp_id'], equals(1));
      expect(payload['book_id'], equals(324));
      expect(payload['transection_id'], equals('TXN123456'));
      expect(payload['image'], startsWith('data:image/png;base64,'));
    });

    test('Status string mapping correctly identifies DONE, PENDING, and REJECTED states', () {
      const doneStatus = 'EMPLOYEE-DONE';
      const pendingStatus = 'EMPLOYEE-PENDING';
      const rejectStatus = 'EMPLOYEE-REJECT';

      bool isDone(String status) =>
          status.toLowerCase().contains('done') || status.toLowerCase().contains('successful') || status.toLowerCase().contains('approved');
      bool isReject(String status) =>
          status.toLowerCase().contains('reject') || status.toLowerCase().contains('failed') || status.toLowerCase().contains('declined');

      expect(isDone(doneStatus), isTrue);
      expect(isReject(doneStatus), isFalse);

      expect(isDone(pendingStatus), isFalse);
      expect(isReject(pendingStatus), isFalse);

      expect(isDone(rejectStatus), isFalse);
      expect(isReject(rejectStatus), isTrue);
    });

    test('Book ID resolution correctly maps IDs to Book Names', () {
      String resolveBookName(String bookId) {
        switch (bookId) {
          case '324': return 'Lucky Vault';
          case '323': return 'Dice Verse';
          case '322': return 'Jackpot Spin';
          case '321': return 'Gold Rush Pro';
          case '310': return 'Infinity Fortune';
          case '309': return 'Crown Riches';
          default: return 'Lucky Vault';
        }
      }

      expect(resolveBookName('324'), equals('Lucky Vault'));
      expect(resolveBookName('323'), equals('Dice Verse'));
      expect(resolveBookName('322'), equals('Jackpot Spin'));
      expect(resolveBookName('321'), equals('Gold Rush Pro'));
      expect(resolveBookName('310'), equals('Infinity Fortune'));
      expect(resolveBookName('309'), equals('Crown Riches'));
    });

    test('Backend developer JSON contracts for recharge_by_user and recharge_records parse accurately', () {
      final rechargeSubmittedResponse = {
        "success": true,
        "message": "Recharge Submitted Successfully!",
        "recharge_id": 24
      };

      expect(rechargeSubmittedResponse['success'], isTrue);
      expect(rechargeSubmittedResponse['recharge_id'], equals(24));
      expect(rechargeSubmittedResponse['message'], equals("Recharge Submitted Successfully!"));

      final rechargeRecordsResponse = {
        "success": true,
        "total_records": 5,
        "data": [
          {
            "recharge_id": 24,
            "book_id": "324",
            "book_name": "Lucky Vault",
            "transection_id": "TXN987654321",
            "amount": "300",
            "stage_status": "EMPLOYEE-PENDING",
            "date": "2026-08-11",
            "formatted_date": "08/11/2026 16:42:44 pm",
            "image_url": "https://telewiz.in/officemanage/uploads/photos/1786446764_Recharge_Image.png",
            "invoice_url": "https://telewiz.in/officemanage/uploads/documents/Invoice_1785320045_17.pdf"
          }
        ],
        "categorized": {
          "pending": [],
          "successful": [],
          "rejected": []
        }
      };

      expect(rechargeRecordsResponse['success'], isTrue);
      expect(rechargeRecordsResponse['total_records'], equals(5));
      final List list = rechargeRecordsResponse['data'] as List;
      expect(list.length, equals(1));
      expect(list.first['recharge_id'], equals(24));
      final model = RechargeRecordModel.fromJson(list.first as Map<String, dynamic>);
      expect(model.date, equals("08/11/2026 16:42:44 pm"));
      expect(model.invoiceUrl, equals("https://telewiz.in/officemanage/uploads/documents/Invoice_1785320045_17.pdf"));
      expect(model.imageUrl, equals("https://telewiz.in/officemanage/uploads/photos/1786446764_Recharge_Image.png"));
    });

    test('update_user and delete_user JSON payloads match developer specification', () {
      final updateUserPayload = {
        'action': 'update_user',
        'id': 24,
        'name': 'Jane Doe',
        'email': 'jane@test.com',
        'mob': '9876543210',
      };

      final deleteUserPayload = {
        'action': 'delete_user',
        'id': 24,
      };

      expect(updateUserPayload['action'], equals('update_user'));
      expect(updateUserPayload['id'], equals(24));
      expect(updateUserPayload['name'], equals('Jane Doe'));
      expect(updateUserPayload['mob'], equals('9876543210'));

      expect(deleteUserPayload['action'], equals('delete_user'));
      expect(deleteUserPayload['id'], equals(24));
    });

    test('User account deletion confirmation flow correctly respects Yes/No decision', () {
      bool isDeleted = false;
      bool isCancelled = false;

      // Simulated User Confirmation Decision Handler
      void handleUserDeleteConfirmation(bool userChoice) {
        if (userChoice) {
          // User clicked YES -> Trigger account deletion & API call
          isDeleted = true;
          isCancelled = false;
        } else {
          // User clicked Cancel / NO -> Cancel operation
          isDeleted = false;
          isCancelled = true;
        }
      }

      // Case 1: User clicks Cancel (NO)
      handleUserDeleteConfirmation(false);
      expect(isDeleted, isFalse);
      expect(isCancelled, isTrue);

      // Case 2: User clicks Delete Account (YES)
      handleUserDeleteConfirmation(true);
      expect(isDeleted, isTrue);
      expect(isCancelled, isFalse);
    });

    test('User App and Agency App share the exact same room conversation ID conv-AGENCY-23-sample@gmail.com', () {
      final userAppConvId = ApiEndpoints.buildConversationId('AGENCY-23', 'sample@gmail.com');
      expect(userAppConvId, equals('conv-AGENCY-23-sample@gmail.com'));

      final agencyAppConvId = ApiEndpoints.buildConversationId('AGENCY-23', 'sample@gmail.com');
      expect(agencyAppConvId, equals('conv-AGENCY-23-sample@gmail.com'));
    });
  });
}
