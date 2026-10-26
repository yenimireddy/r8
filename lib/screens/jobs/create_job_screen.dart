import 'package:flutter/material.dart';
import '../../data/r8_store.dart';
import '../../models/models.dart';

class CreateJobScreen extends StatefulWidget {
  const CreateJobScreen({super.key, required this.store});
  final R8Store store;

  @override
  State<CreateJobScreen> createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends State<CreateJobScreen> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _location = TextEditingController(text: 'Mandasa (general area)');
  final _amount = TextEditingController();
  final _schedule = TextEditingController();
  String _category = categories.first;
  PriceMode _priceMode = PriceMode.fixed;
  DurationType _duration = DurationType.fullDay;
  String? _error;
  bool _submitting = false;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _location.dispose();
    _amount.dispose();
    _schedule.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final job = await widget.store.createJob(
      title: _title.text,
      description: _desc.text,
      category: _category,
      approxLocation: _location.text,
      priceMode: _priceMode,
      durationType: _duration,
      fixedAmount: _priceMode == PriceMode.fixed
          ? double.tryParse(_amount.text)
          : null,
      scheduleNote: _schedule.text,
    );
    if (job == null) {
      setState(() {
        _error = widget.store.lastError;
        _submitting = false;
      });
      return;
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post a job')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _title, decoration: const InputDecoration(labelText: 'Title')),
          const SizedBox(height: 12),
          TextField(
            controller: _desc,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _category,
            items: categories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _category = v!),
            decoration: const InputDecoration(labelText: 'Category'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _location,
            decoration: const InputDecoration(
              labelText: 'Approximate location (not home address)',
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<PriceMode>(
            value: _priceMode,
            items: const [
              DropdownMenuItem(value: PriceMode.fixed, child: Text('Fixed price')),
              DropdownMenuItem(value: PriceMode.negotiable, child: Text('Negotiable')),
              DropdownMenuItem(value: PriceMode.quoteRequest, child: Text('Request a quote')),
            ],
            onChanged: (v) => setState(() => _priceMode = v!),
            decoration: const InputDecoration(labelText: 'Pricing'),
          ),
          if (_priceMode == PriceMode.fixed) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _amount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount (₹)'),
            ),
          ],
          const SizedBox(height: 12),
          DropdownButtonFormField<DurationType>(
            value: _duration,
            items: DurationType.values
                .map((d) => DropdownMenuItem(value: d, child: Text(d.name)))
                .toList(),
            onChanged: (v) => setState(() => _duration = v!),
            decoration: const InputDecoration(labelText: 'Duration'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _schedule,
            decoration: const InputDecoration(labelText: 'Schedule note'),
          ),
          const SizedBox(height: 12),
          Text(
            'Payment happens outside R8. R8 does not guarantee payment or workmanship.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: Text(_submitting ? 'Posting…' : 'Publish job'),
          ),
        ],
      ),
    );
  }
}
