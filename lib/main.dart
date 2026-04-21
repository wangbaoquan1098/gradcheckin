import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/countdown_provider.dart';
import 'providers/checkin_provider.dart';
import 'providers/settings_provider.dart';
import 'core/services/app_settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppSettingsService.loadFromPrefs();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CountdownProvider()),
        ChangeNotifierProvider(create: (_) => CheckinProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: const GradCheckinApp(),
    ),
  );
}
