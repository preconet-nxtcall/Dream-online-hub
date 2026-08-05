abstract class NetworkInfo {
  Future<bool> get isConnected;
}

class NetworkInfoImpl implements NetworkInfo {
  @override
  Future<bool> get isConnected async {
    // Implement connectivity check (e.g. using connectivity_plus)
    return true;
  }
}
