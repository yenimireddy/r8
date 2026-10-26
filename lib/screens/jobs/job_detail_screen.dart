import 'package:flutter/material.dart';
import '../../data/r8_store.dart';
import '../../models/models.dart';
import '../chat/chat_screen.dart';

class JobDetailScreen extends StatefulWidget {
  const JobDetailScreen({super.key, required this.store, required this.jobId});
  final R8Store store;
  final String jobId;

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  final _scope = TextEditingController(text: 'As described');
  final _amount = TextEditingController();
  final _schedule = TextEditingController();
  final _review = TextEditingController();
  int _rating = 5;

  @override
  void dispose() {
    _scope.dispose();
    _amount.dispose();
    _schedule.dispose();
    _review.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final store = widget.store;
        final job = store.jobs.cast<Job?>().firstWhere(
              (j) => j!.id == widget.jobId,
              orElse: () => null,
            );
        if (job == null) {
          return const Scaffold(body: Center(child: Text('Job not found')));
        }
        final me = store.currentUser!;
        final isOwner = job.ownerId == me.id;
        final jobOffers = store.offersForJob(job.id);
        final confirmed = jobOffers.cast<Offer?>().firstWhere(
              (o) => o!.status == OfferStatus.confirmed,
              orElse: () => null,
            );

        return Scaffold(
          appBar: AppBar(
            title: Text(job.title),
            actions: [
              IconButton(
                icon: const Icon(Icons.flag_outlined),
                onPressed: () {
                  store.report(
                    target: ReportTarget.job,
                    targetId: job.id,
                    reason: 'Reported job',
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Job reported')),
                  );
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(job.description),
              const SizedBox(height: 8),
              Text('Status: ${job.status.name}'),
              Text('Category: ${job.category}'),
              Text('Area: ${job.approxLocation}'),
              Text('Duration: ${job.durationType.name}'),
              Text('Schedule: ${job.scheduleNote}'),
              Text('Pricing: ${job.priceMode.name}'
                  '${job.fixedAmount != null ? " · ₹${job.fixedAmount!.toStringAsFixed(0)}" : ""}'),
              if (job.hasDispute) const Text('Dispute open (separate from completion)'),
              if (job.noShowReported) const Text('No-show reported (no auto-punishment)'),
              const Divider(height: 32),
              const Text('Offers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              if (jobOffers.isEmpty) const Text('No offers yet'),
              ...jobOffers.map((o) {
                final worker = store.user(o.workerId);
                return Card(
                  child: ListTile(
                    title: Text('${worker?.displayName ?? o.workerId} · ₹${o.amount.toStringAsFixed(0)}'),
                    subtitle: Text('${o.scope}\n${o.schedule}\n${o.status.name}'),
                    isThreeLine: true,
                    trailing: isOwner && o.status == OfferStatus.pending
                        ? Wrap(
                            children: [
                              TextButton(
                                onPressed: () => store.customerAcceptOffer(o.id),
                                child: const Text('Accept'),
                              ),
                              TextButton(
                                onPressed: () => store.declineOffer(o.id),
                                child: const Text('Decline'),
                              ),
                            ],
                          )
                        : (!isOwner &&
                                o.workerId == me.id &&
                                o.status == OfferStatus.customerAccepted)
                            ? FilledButton(
                                onPressed: () => store.workerConfirmOffer(o.id),
                                child: const Text('Confirm terms'),
                              )
                            : null,
                  ),
                );
              }),
              if (!isOwner && confirmed == null) ...[
                const Divider(height: 32),
                const Text('Submit offer', style: TextStyle(fontWeight: FontWeight.bold)),
                TextField(controller: _scope, decoration: const InputDecoration(labelText: 'Scope')),
                TextField(
                  controller: _amount,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Amount ₹'),
                ),
                TextField(controller: _schedule, decoration: const InputDecoration(labelText: 'Schedule')),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () {
                    final amt = double.tryParse(_amount.text);
                    if (amt == null) return;
                    store.submitOffer(
                      jobId: job.id,
                      scope: _scope.text,
                      amount: amt,
                      schedule: _schedule.text,
                    );
                  },
                  child: const Text('Send offer'),
                ),
                TextButton(
                  onPressed: () {
                    try {
                      final c = store.startChat(job.ownerId, jobId: job.id);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(store: store, conversationId: c.id),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                    }
                  },
                  child: const Text('Ask a question in chat'),
                ),
              ],
              if (confirmed != null) ...[
                const Divider(height: 32),
                const Text('Booking actions', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Chat does not confirm booking — both parties accepted terms.'),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: () => store.markInProgress(job.id),
                      child: const Text('Mark in progress'),
                    ),
                    if (isOwner)
                      FilledButton(
                        onPressed: () => store.confirmCompletion(job.id, asCustomer: true),
                        child: const Text('Customer: confirm done'),
                      ),
                    if (!isOwner && confirmed.workerId == me.id)
                      FilledButton(
                        onPressed: () => store.confirmCompletion(job.id, asCustomer: false),
                        child: const Text('Worker: confirm done'),
                      ),
                    TextButton(
                      onPressed: () => store.cancelJob(job.id, 'Cancelled by user'),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => store.reportNoShow(job.id),
                      child: const Text('Report no-show'),
                    ),
                    TextButton(
                      onPressed: () => store.openDispute(job.id),
                      child: const Text('Open dispute'),
                    ),
                  ],
                ),
              ],
              if (job.status == JobStatus.completed) ...[
                const Divider(height: 32),
                const Text('Review (completed jobs only)'),
                Row(
                  children: [
                    const Text('Rating'),
                    Slider(
                      value: _rating.toDouble(),
                      min: 1,
                      max: 5,
                      divisions: 4,
                      label: '$_rating',
                      onChanged: (v) => setState(() => _rating = v.round()),
                    ),
                  ],
                ),
                TextField(controller: _review, decoration: const InputDecoration(labelText: 'Review')),
                FilledButton(
                  onPressed: () {
                    final recipient = isOwner ? confirmed!.workerId : job.ownerId;
                    final err = store.addReview(
                      jobId: job.id,
                      recipientId: recipient,
                      rating: _rating,
                      text: _review.text,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(err ?? 'Review saved')),
                    );
                  },
                  child: const Text('Submit review'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
