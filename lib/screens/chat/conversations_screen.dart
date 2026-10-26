import 'package:flutter/material.dart';
import '../../data/mock_store.dart';
import 'chat_screen.dart';

class ConversationsScreen extends StatelessWidget {
  const ConversationsScreen({super.key, required this.store});
  final MockStore store;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final me = store.currentUser!;
        final mine = store.conversations
            .where((c) => c.participantIds.contains(me.id))
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        return Scaffold(
          appBar: AppBar(title: const Text('Chat')),
          body: mine.isEmpty
              ? const Center(child: Text('No conversations yet. Start from a profile or job.'))
              : ListView.separated(
                  itemCount: mine.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final c = mine[i];
                    final otherId = c.participantIds.firstWhere((id) => id != me.id);
                    final other = store.user(otherId);
                    return ListTile(
                      leading: CircleAvatar(child: Text((other?.displayName ?? '?')[0])),
                      title: Text(other?.displayName ?? otherId),
                      subtitle: Text(c.blocked
                          ? 'Blocked'
                          : (c.jobId != null ? 'Job chat · ${c.jobId}' : 'Direct chat')),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(store: store, conversationId: c.id),
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
