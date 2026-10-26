import 'package:flutter/material.dart';
import '../../data/r8_store.dart';
import '../../models/models.dart';
import '../chat/chat_screen.dart';

class ProfileDetailScreen extends StatelessWidget {
  const ProfileDetailScreen({super.key, required this.store, required this.userId});
  final R8Store store;
  final String userId;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final u = store.user(userId);
        if (u == null) {
          return const Scaffold(body: Center(child: Text('User not found')));
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(u.displayName),
            actions: [
              PopupMenuButton<String>(
                onSelected: (v) async {
                  if (v == 'block') {
                    store.blockUser(u.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User blocked')),
                    );
                    Navigator.pop(context);
                  } else if (v == 'report') {
                    store.report(
                      target: ReportTarget.profile,
                      targetId: u.id,
                      reason: 'Reported from profile',
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Report submitted for review')),
                    );
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'report', child: Text('Report')),
                  PopupMenuItem(value: 'block', child: Text('Block')),
                ],
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(u.bio.isEmpty ? 'No bio yet' : u.bio),
              const SizedBox(height: 12),
              _row('Public location', u.location.display),
              _row('Languages', u.languages.join(', ')),
              if (u.isWorker) ...[
                _row('Categories', u.categories.join(', ')),
                _row('Skills', u.skills.join(', ')),
                _row('Experience', u.experience),
                _row('Service area', u.serviceArea),
                _row('Availability', u.availability),
                _row('Price guidance', u.priceGuidance),
              ],
              const SizedBox(height: 8),
              Text(
                'Phone number and home address are private. '
                'Exact GPS is never shown on profiles.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Not identity-verified or professionally certified by R8.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                icon: const Icon(Icons.chat),
                label: const Text('Chat (no connection needed)'),
                onPressed: () {
                  try {
                    final c = store.startChat(u.id);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(store: store, conversationId: c.id),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$e')),
                    );
                  }
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _row(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
