import 'package:flutter/foundation.dart';
import '../models/user/recharge_record_model.dart';
import '../repositories/employee_repository.dart';

class EmployeeProvider extends ChangeNotifier {
  final EmployeeRepository _repository;

  List<RechargeRecordModel> _recharges = [];
  List<RechargeRecordModel> _withdrawals = [];

  bool _isLoadingRecharges = false;
  bool _isLoadingWithdrawals = false;
  bool _isProcessingAction = false;
  String? _errorMessage;

  String _rechargeSearchQuery = '';
  String _withdrawalSearchQuery = '';
  String _rechargeFilter = 'all'; // 'all', 'pending', 'successful', 'rejected'
  String _withdrawalFilter =
      'all'; // 'all', 'pending', 'successful', 'rejected'

  String? _currentAgencyId;
  String? _currentEmployeeUserId;

  EmployeeProvider({EmployeeRepository? repository})
      : _repository = repository ?? EmployeeRepositoryImpl();

  // Getters
  List<RechargeRecordModel> get recharges => _recharges;
  List<RechargeRecordModel> get withdrawals => _withdrawals;

  bool get isLoadingRecharges => _isLoadingRecharges;
  bool get isLoadingWithdrawals => _isLoadingWithdrawals;
  bool get isProcessingAction => _isProcessingAction;
  String? get errorMessage => _errorMessage;
  String? get currentAgencyId => _currentAgencyId;
  String? get currentEmployeeUserId => _currentEmployeeUserId;

  String get rechargeSearchQuery => _rechargeSearchQuery;
  String get withdrawalSearchQuery => _withdrawalSearchQuery;
  String get rechargeFilter => _rechargeFilter;
  String get withdrawalFilter => _withdrawalFilter;

  void setAgencyId(String? agencyId) {
    _currentAgencyId = agencyId;
    notifyListeners();
  }

  void setEmployeeContext({String? agencyId, String? employeeUserId}) {
    _currentAgencyId = agencyId;
    _currentEmployeeUserId = employeeUserId;
    notifyListeners();
  }

  void setRechargeFilter(String filter) {
    _rechargeFilter = filter;
    notifyListeners();
  }

  void setWithdrawalFilter(String filter) {
    _withdrawalFilter = filter;
    notifyListeners();
  }

  void searchRecharges(String query) {
    _rechargeSearchQuery = query;
    notifyListeners();
  }

  void searchWithdrawals(String query) {
    _withdrawalSearchQuery = query;
    notifyListeners();
  }

  List<RechargeRecordModel> get agencyScopedRecharges {
    final cleanAgency = _currentAgencyId?.replaceAll(RegExp(r'\D'), '');
    final cleanEmpUser = _currentEmployeeUserId?.replaceAll(RegExp(r'\D'), '');
    final targetId = (cleanAgency != null && cleanAgency.isNotEmpty)
        ? cleanAgency
        : cleanEmpUser;

    // Agency Employee manages their Agency's records (Agency and Agency Employee share agency ID scope)
    if (targetId != null && targetId.isNotEmpty) {
      return _recharges.where((r) {
        final rAgency = r.agencyId?.replaceAll(RegExp(r'\D'), '');
        final rEmp = r.empId?.replaceAll(RegExp(r'\D'), '');
        if ((rAgency != null && rAgency.isNotEmpty) ||
            (rEmp != null && rEmp.isNotEmpty)) {
          return rAgency == targetId || rEmp == targetId;
        }
        return true;
      }).toList();
    }

    return _recharges;
  }

  List<RechargeRecordModel> get agencyScopedWithdrawals {
    final cleanAgency = _currentAgencyId?.replaceAll(RegExp(r'\D'), '');
    final cleanEmpUser = _currentEmployeeUserId?.replaceAll(RegExp(r'\D'), '');
    final targetId = (cleanAgency != null && cleanAgency.isNotEmpty)
        ? cleanAgency
        : cleanEmpUser;

    // Agency Employee manages their Agency's withdrawals (Matches agency-withdraw-req.php & agency-withdraw-pending.php)
    // Raw EMPLOYEE-PENDING records belong only to Central Head Office Employee (emp-withdraw-req.php)
    if (targetId != null && targetId.isNotEmpty) {
      return _withdrawals.where((w) {
        final wAgency = w.agencyId?.replaceAll(RegExp(r'\D'), '');
        final wEmp = w.empId?.replaceAll(RegExp(r'\D'), '');
        final matchesAgency = (wAgency != null && wAgency.isNotEmpty) ||
                (wEmp != null && wEmp.isNotEmpty)
            ? (wAgency == targetId || wEmp == targetId)
            : true;
        if (!matchesAgency) return false;

        // Exclude unpassed EMPLOYEE-PENDING requests from Agency portal
        final statusUpper = w.status.toUpperCase();
        if (statusUpper == 'EMPLOYEE-PENDING' || statusUpper == 'PENDING') {
          return false;
        }

        return true;
      }).toList();
    }

    return _withdrawals.where((w) {
      final statusUpper = w.status.toUpperCase();
      return statusUpper != 'EMPLOYEE-PENDING' && statusUpper != 'PENDING';
    }).toList();
  }

  int get allRechargesCount =>
      pendingRechargesCount + successfulRechargesCount + rejectedRechargesCount;

  int get successfulRechargesCount => agencyScopedRecharges.where((r) {
        final st = r.status.toUpperCase();
        return st == 'EMPLOYEE-DONE' ||
            st == 'AGENCY-DONE' ||
            st.contains('DONE') ||
            st.contains('SUCCESS') ||
            st.contains('APPROV');
      }).length;

  int get rejectedRechargesCount => agencyScopedRecharges.where((r) {
        final st = r.status.toUpperCase();
        return st.contains('REJECT') ||
            st.contains('FAIL') ||
            st.contains('DECLIN');
      }).length;

  int get pendingRechargesCount => agencyScopedRecharges.where((r) {
        final st = r.status.toUpperCase();
        final isDone = st == 'EMPLOYEE-DONE' ||
            st == 'AGENCY-DONE' ||
            st.contains('DONE') ||
            st.contains('SUCCESS') ||
            st.contains('APPROV');
        final isReject = st.contains('REJECT') ||
            st.contains('FAIL') ||
            st.contains('DECLIN');
        return !isDone && !isReject;
      }).length;

  int get allWithdrawalsCount =>
      pendingWithdrawalsCount +
      successfulWithdrawalsCount +
      rejectedWithdrawalsCount;

  int get successfulWithdrawalsCount => agencyScopedWithdrawals.where((w) {
        final st = w.status.toUpperCase();
        return st == 'EMPLOYEE-DONE' ||
            st == 'AGENCY-DONE' ||
            st.contains('DONE') ||
            st.contains('SUCCESS') ||
            st.contains('APPROV');
      }).length;

  int get rejectedWithdrawalsCount => agencyScopedWithdrawals.where((w) {
        final st = w.status.toUpperCase();
        return st.contains('REJECT') ||
            st.contains('FAIL') ||
            st.contains('DECLIN');
      }).length;

  int get pendingWithdrawalsCount => agencyScopedWithdrawals.where((w) {
        final st = w.status.toUpperCase();
        final isDone = st == 'EMPLOYEE-DONE' ||
            st == 'AGENCY-DONE' ||
            st.contains('DONE') ||
            st.contains('SUCCESS') ||
            st.contains('APPROV');
        final isReject = st.contains('REJECT') ||
            st.contains('FAIL') ||
            st.contains('DECLIN');
        return !isDone && !isReject;
      }).length;

  int get totalPendingCount => pendingRechargesCount + pendingWithdrawalsCount;

  List<RechargeRecordModel> get filteredRecharges {
    return agencyScopedRecharges.where((record) {
      final statusUpper = record.status.toUpperCase();
      final isDone = statusUpper == 'EMPLOYEE-DONE' ||
          statusUpper == 'AGENCY-DONE' ||
          statusUpper.contains('DONE') ||
          statusUpper.contains('SUCCESS') ||
          statusUpper.contains('APPROV');
      final isReject = statusUpper.contains('REJECT') ||
          statusUpper.contains('FAIL') ||
          statusUpper.contains('DECLIN');
      final isPending = !isDone && !isReject;

      // Filter by chip status
      if (_rechargeFilter == 'pending' && !isPending) {
        return false;
      } else if (_rechargeFilter == 'successful' && !isDone) {
        return false;
      } else if (_rechargeFilter == 'rejected' && !isReject) {
        return false;
      } else if (_rechargeFilter == 'all' &&
          (!isDone && !isReject && !isPending)) {
        return false;
      }

      if (_rechargeSearchQuery.trim().isNotEmpty) {
        final q = _rechargeSearchQuery.trim().toLowerCase();
        final id = record.id.toLowerCase();
        final user = (record.userName ?? '').toLowerCase();
        final book = record.bookName.toLowerCase();
        final txn = record.transactionDetails.toLowerCase();
        final amt = record.amount.toString();

        return id.contains(q) ||
            user.contains(q) ||
            book.contains(q) ||
            txn.contains(q) ||
            amt.contains(q);
      }

      return true;
    }).toList();
  }

  List<RechargeRecordModel> get filteredWithdrawals {
    return agencyScopedWithdrawals.where((record) {
      final statusUpper = record.status.toUpperCase();
      final isDone = statusUpper == 'EMPLOYEE-DONE' ||
          statusUpper == 'AGENCY-DONE' ||
          statusUpper.contains('DONE') ||
          statusUpper.contains('SUCCESS') ||
          statusUpper.contains('APPROV');
      final isReject = statusUpper.contains('REJECT') ||
          statusUpper.contains('FAIL') ||
          statusUpper.contains('DECLIN');
      final isPending = !isDone && !isReject;

      if (_withdrawalFilter == 'pending' && !isPending) {
        return false;
      } else if (_withdrawalFilter == 'successful' && !isDone) {
        return false;
      } else if (_withdrawalFilter == 'rejected' && !isReject) {
        return false;
      } else if (_withdrawalFilter == 'all' &&
          (!isDone && !isReject && !isPending)) {
        return false;
      }

      if (_withdrawalSearchQuery.trim().isNotEmpty) {
        final q = _withdrawalSearchQuery.trim().toLowerCase();
        final id = record.id.toLowerCase();
        final user = (record.userName ?? '').toLowerCase();
        final book = record.bookName.toLowerCase();
        final txn = record.transactionDetails.toLowerCase();
        final amt = record.amount.toString();

        return id.contains(q) ||
            user.contains(q) ||
            book.contains(q) ||
            txn.contains(q) ||
            amt.contains(q);
      }

      return true;
    }).toList();
  }

  /// Fetch all employee data
  Future<void> refreshAll() async {
    await Future.wait([
      fetchRecharges(),
      fetchWithdrawals(),
    ]);
  }

  /// Fetch recharge records
  Future<void> fetchRecharges() async {
    _isLoadingRecharges = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final list = await _repository.fetchRechargeRecords(statusType: 'all');
      _recharges = list;
    } catch (e) {
      _errorMessage = 'Failed to load recharge records.';
    } finally {
      _isLoadingRecharges = false;
      notifyListeners();
    }
  }

  /// Fetch withdrawal records
  Future<void> fetchWithdrawals() async {
    _isLoadingWithdrawals = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final list = await _repository.fetchWithdrawalRecords(statusType: 'all');
      _withdrawals = list;
    } catch (e) {
      _errorMessage = 'Failed to load withdrawal records.';
    } finally {
      _isLoadingWithdrawals = false;
      notifyListeners();
    }
  }

  /// Verify / Approve / Reject Recharge Request
  Future<bool> verifyRecharge({
    required RechargeRecordModel item,
    required String newStatus,
    required String remark,
    String? transactionId,
  }) async {
    _isProcessingAction = true;
    notifyListeners();

    try {
      final success = await _repository.verifyRecharge(
        id: item.id,
        status: newStatus,
        remark: remark,
        transactionId: transactionId,
      );

      // Update in-memory state immediately
      final cleanTargetId = item.id.replaceAll(RegExp(r'\D'), '');
      final idx = _recharges.indexWhere(
        (r) =>
            r.id == item.id ||
            r.id.replaceAll(RegExp(r'\D'), '') == cleanTargetId,
      );

      if (idx != -1) {
        _recharges[idx] = RechargeRecordModel(
          id: _recharges[idx].id,
          bookName: _recharges[idx].bookName,
          userName: _recharges[idx].userName,
          transactionDetails:
              (transactionId != null && transactionId.isNotEmpty)
                  ? transactionId
                  : _recharges[idx].transactionDetails,
          amount: _recharges[idx].amount,
          status: newStatus,
          date: _recharges[idx].date,
          imageUrl: _recharges[idx].imageUrl,
          invoiceUrl: _recharges[idx].invoiceUrl,
        );
      }

      return success;
    } finally {
      _isProcessingAction = false;
      notifyListeners();
    }
  }

  /// Verify / Pass / Approve / Reject Withdrawal Request
  Future<bool> verifyWithdrawal({
    required RechargeRecordModel item,
    required String newStatus,
    required String remark,
    String? transactionId,
  }) async {
    _isProcessingAction = true;
    notifyListeners();

    try {
      final success = await _repository.verifyWithdrawal(
        id: item.id,
        status: newStatus,
        remark: remark,
        transactionId: transactionId,
      );

      // Update in-memory state immediately
      final cleanTargetId = item.id.replaceAll(RegExp(r'\D'), '');
      final idx = _withdrawals.indexWhere(
        (w) =>
            w.id == item.id ||
            w.id.replaceAll(RegExp(r'\D'), '') == cleanTargetId,
      );

      if (idx != -1) {
        _withdrawals[idx] = RechargeRecordModel(
          id: _withdrawals[idx].id,
          bookName: _withdrawals[idx].bookName,
          userName: _withdrawals[idx].userName,
          transactionDetails: _withdrawals[idx].transactionDetails,
          amount: _withdrawals[idx].amount,
          status: newStatus,
          date: _withdrawals[idx].date,
          imageUrl: _withdrawals[idx].imageUrl,
          invoiceUrl: _withdrawals[idx].invoiceUrl,
        );
      }

      return success;
    } finally {
      _isProcessingAction = false;
      notifyListeners();
    }
  }
}
