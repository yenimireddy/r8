import 'package:flutter/material.dart';
import '../../data/mock_store.dart';
import '../../models/models.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.store});
  final MockStore store;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _bio;
  late final TextEditingController _town;
  late final TextEditingController _district;
  late final TextEditingController _state;
  late final TextEditingController _pin;
  late final TextEditingController _skills;
  late final TextEditingController _experience;
  late final TextEditingController _serviceArea;
  late final TextEditingController _availability;
  late final TextEditingController _price;
  late bool _showPin;
  late Set<String> _selectedCategories;

  @override
  void initState() {
    super.initState();
    final me = widget.store.currentUser!;
    _name = TextEditingController(text: me.displayName);
    _bio = TextEditingController(text: me.bio);
    _town = TextEditingController(text: me.location.town ?? '');
    _district = TextEditingController(text: me.location.district ?? '');
    _state = TextEditingController(text: me.location.state ?? '');
    _pin = TextEditingController(text: me.location.pin ?? '');
    _showPin = me.location.showPin;
    _skills = TextEditingController(text: me.skills.join(', '));
    _experience = TextEditingController(text: me.experience);
    _serviceArea = TextEditingController(text: me.serviceArea);
    _availability = TextEditingController(text: me.availability);
    _price = TextEditingController(text: me.priceGuidance);
    _selectedCategories = Set.of(me.categories);
  }

  @override
  void dispose() {
    for (final c in [_name, _bio, _town, _district, _state, _pin, _skills, _experience, _serviceArea, _availability, _price]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    final me = widget.store.currentUser!.copy();
    me.displayName = _name.text.trim().isEmpty ? me.displayName : _name.text.trim();
    me.bio = _bio.text.trim();
    me.location = PublicLocation(
      town: _town.text.trim(),
      district: _district.text.trim(),
      state: _state.text.trim(),
      pin: _pin.text.trim(),
      showPin: _showPin,
    );
    me.categories = _selectedCategories.toList();
    me.skills = _skills.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    me.experience = _experience.text.trim();
    me.serviceArea = _serviceArea.text.trim();
    me.availability = _availability.text.trim();
    me.priceGuidance = _price.text.trim();
    widget.store.updateProfile(me);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit profile'),
        actions: [TextButton(onPressed: _save, child: const Text('Save'))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Display name')),
          const SizedBox(height: 12),
          TextField(controller: _bio, maxLines: 3, decoration: const InputDecoration(labelText: 'Bio')),
          const SizedBox(height: 16),
          Text('Public location (never home address / GPS)', style: Theme.of(context).textTheme.titleSmall),
          TextField(controller: _town, decoration: const InputDecoration(labelText: 'Town / locality')),
          TextField(controller: _district, decoration: const InputDecoration(labelText: 'District')),
          TextField(controller: _state, decoration: const InputDecoration(labelText: 'State')),
          TextField(controller: _pin, decoration: const InputDecoration(labelText: 'PIN code (optional)')),
          SwitchListTile(
            title: const Text('Show PIN on public profile'),
            value: _showPin,
            onChanged: (v) => setState(() => _showPin = v),
          ),
          const SizedBox(height: 8),
          Text('Worker details (optional — same account can hire & offer)', style: Theme.of(context).textTheme.titleSmall),
          Wrap(
            spacing: 8,
            children: categories
                .map((c) => FilterChip(
                      label: Text(c),
                      selected: _selectedCategories.contains(c),
                      onSelected: (sel) => setState(() {
                        if (sel) {
                          _selectedCategories.add(c);
                        } else {
                          _selectedCategories.remove(c);
                        }
                      }),
                    ))
                .toList(),
          ),
          TextField(controller: _skills, decoration: const InputDecoration(labelText: 'Skills (comma-separated)')),
          TextField(controller: _experience, decoration: const InputDecoration(labelText: 'Experience')),
          TextField(controller: _serviceArea, decoration: const InputDecoration(labelText: 'Service area')),
          TextField(controller: _availability, decoration: const InputDecoration(labelText: 'Availability')),
          TextField(controller: _price, decoration: const InputDecoration(labelText: 'Price guidance')),
          const SizedBox(height: 12),
          Text(
            'Manual location entry only in this mock. GPS would be requested only if you choose device detection later.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
