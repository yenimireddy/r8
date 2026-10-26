import 'package:flutter/material.dart';
import '../../data/r8_store.dart';
import '../../models/models.dart';

class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key, required this.store});
  final R8Store store;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Admin · reports')),
          body: store.reports.isEmpty
              ? const Center(child: Text('No reports'))
              : ListView.builder(
                  itemCount: store.reports.length,
                  itemBuilder: (context, i) {
                    final r = store.reports[i];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        title: Text('${r.target.name} · ${r.status.name}'),
                        subtitle: Text('${r.reason}\nTarget: ${r.targetId}\nNotes: ${r.adminNotes}\nAction: ${r.actionTaken}'),
                        isThreeLine: true,
                        trailing: r.status == ReportStatus.open
                            ? TextButton(
                                child: const Text('Resolve'),
                                onPressed: () => store.adminResolveReport(
                                  r.id,
                                  'Reviewed manually',
                                  'Warned — no auto-ban (BR-10)',
                                ),
                              )
                            : null,
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
