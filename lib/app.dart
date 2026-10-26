import 'package:flutter/material.dart';

import 'data/r8_store.dart';
import 'screens/auth/login_screen.dart';
import 'screens/shell/home_shell.dart';
import 'theme/app_theme.dart';

class R8App extends StatelessWidget {
  const R8App({super.key, required this.store, this.usingMock = false});

  final R8Store store;
  final bool usingMock;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        return MaterialApp(
          title: 'R8',
          debugShowCheckedModeBanner: usingMock,
          theme: AppTheme.light,
          home: store.currentUser == null
              ? LoginScreen(store: store, usingMock: usingMock)
              : HomeShell(store: store),
        );
      },
    );
  }
}
