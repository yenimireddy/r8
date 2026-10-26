import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/r8_store.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({
    super.key,
    required this.store,
    required this.phone,
    required this.verificationId,
    this.usingMock = false,
  });

  final R8Store store;
  final String phone;
  final String verificationId;
  final bool usingMock;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otp = TextEditingController();
  String? _error;
  bool _submitting = false;

  @override
  void dispose() {
    _otp.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });

    final code = _otp.text.trim();
    bool ok;
    if (widget.usingMock) {
      final mock = widget.store;
      if (mock is MockR8Store) mock.setPendingPhone(widget.phone);
      ok = await widget.store.verifyOtp(widget.phone, code);
      if (!ok && widget.store is MockR8Store) {
        // R8Store.verifyOtp path via adapter
        ok = await (widget.store as MockR8Store).verifyOtp(widget.phone, code);
      }
    } else {
      ok = await widget.store.confirmPhoneAuth(
        verificationId: widget.verificationId,
        smsCode: code,
      );
    }

    if (!ok) {
      setState(() {
        _error = widget.store.lastError ?? 'Invalid OTP';
        _submitting = false;
      });
      return;
    }
    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final digits = widget.phone.replaceAll(RegExp(r'\D'), '');
    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Code sent to +91 $digits'),
            if (widget.usingMock)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Mock OTP: 123456'),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _otp,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              decoration: const InputDecoration(labelText: '6-digit OTP'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const Spacer(),
            FilledButton(
              onPressed: _submitting ? null : _verify,
              child: Text(_submitting ? 'Checking…' : 'Verify'),
            ),
          ],
        ),
      ),
    );
  }
}
