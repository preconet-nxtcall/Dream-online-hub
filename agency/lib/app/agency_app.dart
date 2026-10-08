import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/agency_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/employee_provider.dart';
import '../routes/agency_routes.dart';
import '../theme/app_theme.dart';

class AgencyApp extends StatelessWidget {
  const AgencyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AgencyProvider()),
        ChangeNotifierProvider(create: (_) => EmployeeProvider()),
      ],
      child: MaterialApp.router(
        title: 'Dream Online Hub Agency',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        themeMode: ThemeMode.light,
        routerConfig: AgencyRoutes.router,
        builder: (context, child) {
          return ScrollConfiguration(
            behavior: const ScrollBehavior().copyWith(
              physics: const BouncingScrollPhysics(),
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
