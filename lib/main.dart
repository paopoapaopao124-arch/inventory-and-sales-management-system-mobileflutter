
import 'package:flutter/material.dart';

import 'config/app_config.dart';
import 'shared/app_theme.dart';
import 'auth/login_page.dart';
import 'data/store_data.dart';
import 'data/user_data.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppConfig.load();
  await StoreData.instance.load();
  await UserData.instance.load();

  runApp(const StockSmartApp());
}

class StockSmartApp extends StatelessWidget {
  const StockSmartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StockSmart',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const LoginPage(),
    );
  }
}
