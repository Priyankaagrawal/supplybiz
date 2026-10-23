import 'package:flutter/material.dart';

import 'core/config/app_environment.dart';

class SupplyBizApp extends StatelessWidget {
  const SupplyBizApp({required this.environment, super.key});

  final AppEnvironment environment;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Supply Biz',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF176B5B)),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('Supply Biz')),
        body: Center(
          child: Text('${environment.displayName} environment'),
        ),
      ),
    );
  }
}

class StartupFailureApp extends StatelessWidget {
  const StartupFailureApp({required this.error, super.key});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Supply Biz startup error',
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Supply Biz could not start. Check the application configuration '
              'and try again.\n\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
