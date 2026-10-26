import 'package:flutter/material.dart';
import '../../data/r8_store.dart';
import '../../models/models.dart';
import 'create_job_screen.dart';
import 'job_detail_screen.dart';

class JobsScreen extends StatelessWidget {
  const JobsScreen({super.key, required this.store});
  final R8Store store;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final me = store.currentUser!;
        final mine = store.jobs.where((j) => j.ownerId == me.id).toList();
        final open = store.jobs.where((j) => j.ownerId != me.id).toList();
        return Scaffold(
          appBar: AppBar(title: const Text('Jobs')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => CreateJobScreen(store: store)),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Post job'),
          ),
          body: ListView(
            children: [
              const ListTile(title: Text('Your jobs', style: TextStyle(fontWeight: FontWeight.bold))),
              if (mine.isEmpty)
                const ListTile(title: Text('No jobs posted yet')),
              ...mine.map((j) => _tile(context, j)),
              const Divider(),
              const ListTile(title: Text('Open jobs near you', style: TextStyle(fontWeight: FontWeight.bold))),
              ...open.map((j) => _tile(context, j)),
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }

  Widget _tile(BuildContext context, Job j) {
    return ListTile(
      title: Text(j.title),
      subtitle: Text('${j.category} · ${j.status.name} · ${j.approxLocation}'),
      trailing: Text(_priceLabel(j)),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => JobDetailScreen(store: store, jobId: j.id),
        ),
      ),
    );
  }

  String _priceLabel(Job j) {
    switch (j.priceMode) {
      case PriceMode.fixed:
        return '₹${j.fixedAmount?.toStringAsFixed(0) ?? "-"}';
      case PriceMode.negotiable:
        return 'Negotiable';
      case PriceMode.quoteRequest:
        return 'Quote';
    }
  }
}
