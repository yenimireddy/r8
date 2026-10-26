import 'package:flutter/material.dart';
import '../../data/r8_store.dart';
import 'profile_detail_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key, required this.store});
  final R8Store store;

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  String? _category;
  final _area = TextEditingController();

  @override
  void dispose() {
    _area.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = widget.store.discover(
      category: _category,
      areaQuery: _area.text,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Discover')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _area,
              decoration: const InputDecoration(
                labelText: 'Area (e.g. Mandasa)',
                prefixIcon: Icon(Icons.place_outlined),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('All'),
                    selected: _category == null,
                    onSelected: (_) => setState(() => _category = null),
                  ),
                ),
                ...categories.map((c) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(c),
                        selected: _category == c,
                        onSelected: (_) => setState(() => _category = c),
                      ),
                    )),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: results.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final u = results[i];
                return ListTile(
                  leading: CircleAvatar(child: Text(u.displayName[0])),
                  title: Text(u.displayName),
                  subtitle: Text(
                    '${u.categories.join(", ")}\n${u.location.display}',
                  ),
                  isThreeLine: true,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProfileDetailScreen(
                        store: widget.store,
                        userId: u.id,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
