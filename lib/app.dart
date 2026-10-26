import 'package:flutter/material.dart';
import 'data/mock_store.dart';
import 'screens/auth/login_screen.dart';
import 'screens/shell/home_shell.dart';
import 'theme/app_theme.dart';

class R8App extends StatelessWidget {
  const R8App({super.key, required this.store});

  final MockStore store;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        return MaterialApp(
          title: 'R8',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: store.currentUser == null
              ? LoginScreen(store: store)
              : HomeShell(store: store),
        );
      },
    );
  }
}
