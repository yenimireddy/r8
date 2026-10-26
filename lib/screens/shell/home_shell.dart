import 'package:flutter/material.dart';
import '../../data/mock_store.dart';
import '../account/account_screen.dart';
import '../chat/conversations_screen.dart';
import '../discover/discover_screen.dart';
import '../jobs/jobs_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.store});
  final MockStore store;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      DiscoverScreen(store: widget.store),
      JobsScreen(store: widget.store),
      ConversationsScreen(store: widget.store),
      AccountScreen(store: widget.store),
    ];
    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.search), label: 'Discover'),
          NavigationDestination(icon: Icon(Icons.work_outline), label: 'Jobs'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Account'),
        ],
      ),
    );
  }
}
