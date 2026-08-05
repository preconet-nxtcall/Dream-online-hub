import 'package:flutter/material.dart';
import 'app/agency_app.dart';
import 'core/constants/app_constants.dart';
import 'core/di/injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize dependency injection & core services
  await di.init(AppFlavor.agency);

  runApp(const AgencyApp());
}
