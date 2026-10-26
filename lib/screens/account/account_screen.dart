import 'package:flutter/material.dart';
import '../../data/mock_store.dart';
import '../admin/admin_reports_screen.dart';
import 'edit_profile_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key, required this.store});
  final MockStore store;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final me = store.currentUser!;
        final myNotes = store.notifications.where((n) => n.recipientId == me.id).toList();
        return Scaffold(
          appBar: AppBar(title: const Text('Account')),
          body: ListView(
            children: [
              ListTile(
                leading: CircleAvatar(child: Text(me.displayName[0])),
                title: Text(me.displayName),
                subtitle: Text('Dual-role account · +91 ${me.phone}'),
              ),
              ListTile(
                title: const Text('Public location'),
                subtitle: Text(me.location.display),
              ),
              if (me.deletionRequested)
                const ListTile(
                  leading: Icon(Icons.warning_amber),
                  title: Text('Account deletion requested'),
                ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit profile & privacy'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => EditProfileScreen(store: store)),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.admin_panel_settings_outlined),
                title: const Text('Admin report queue (mock)'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => AdminReportsScreen(store: store)),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Request account deletion'),
                onTap: () {
                  store.requestAccountDeletion();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Deletion request recorded')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Log out'),
                onTap: store.logout,
              ),
              const Divider(),
              const ListTile(title: Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold))),
              if (myNotes.isEmpty) const ListTile(title: Text('None yet')),
              ...myNotes.take(10).map((n) => ListTile(
                    title: Text(n.title),
                    subtitle: Text(n.body),
                    dense: true,
                  )),
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'R8 facilitates discovery and recording of agreed terms. '
                  'If payment occurs outside R8, the platform does not guarantee '
                  'payment, identity, workmanship or job outcomes.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
