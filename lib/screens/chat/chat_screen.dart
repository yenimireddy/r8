import 'package:flutter/material.dart';
import '../../data/r8_store.dart';
import '../../models/models.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.store, required this.conversationId});
  final R8Store store;
  final String conversationId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final store = widget.store;
        final me = store.currentUser!;
        final c = store.conversations.firstWhere((c) => c.id == widget.conversationId);
        final otherId = c.participantIds.firstWhere((id) => id != me.id);
        final other = store.user(otherId);
        final msgs = store.messagesFor(c.id);

        return Scaffold(
          appBar: AppBar(
            title: Text(other?.displayName ?? 'Chat'),
            actions: [
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'block') {
                    store.blockUser(otherId);
                    Navigator.pop(context);
                  } else if (v == 'report') {
                    store.report(
                      target: ReportTarget.message,
                      targetId: c.id,
                      reason: 'Reported conversation',
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Conversation reported')),
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
          body: Column(
            children: [
              Material(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    'Chat does not confirm a booking. Agree price & schedule via offers.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: msgs.length,
                  itemBuilder: (context, i) {
                    final m = msgs[i];
                    final mineMsg = m.senderId == me.id;
                    return Align(
                      alignment: mineMsg ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: mineMsg
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(m.text),
                      ),
                    );
                  },
                ),
              ),
              SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: TextField(
                          controller: _text,
                          decoration: const InputDecoration(hintText: 'Message'),
                          enabled: !c.blocked,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: c.blocked
                          ? null
                          : () {
                              store.sendMessage(c.id, _text.text);
                              _text.clear();
                            },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
