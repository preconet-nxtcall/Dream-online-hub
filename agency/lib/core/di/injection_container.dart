import '../constants/app_constants.dart';

/// Global dependency injection initialization
Future<void> init(AppFlavor flavor) async {
  // Initialize core services (e.g. storage, networking, push notifications)
  if (flavor == AppFlavor.agency) {
    _initAgencyDependencies();
  } else {
    _initUserDependencies();
  }
}

void _initAgencyDependencies() {
  // Register Agency-specific singletons & repositories
}

void _initUserDependencies() {
  // Register User-specific singletons & repositories
}
