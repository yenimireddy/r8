import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/r8_store.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.store, this.usingMock = false});
  final R8Store store;
  final bool usingMock;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    setState(() {
      _error = null;
      _busy = true;
    });
    if (!widget.store.requestOtp(_phone.text)) {
      setState(() {
        _error = widget.store.lastError;
        _busy = false;
      });
      return;
    }

    if (widget.usingMock || widget.store is MockR8Store) {
      final mock = widget.store;
      if (mock is MockR8Store) mock.setPendingPhone(_phone.text);
      if (!mounted) return;
      setState(() => _busy = false);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OtpScreen(
            store: widget.store,
            phone: _phone.text,
            verificationId: 'mock-verification-id',
            usingMock: true,
          ),
        ),
      );
      return;
    }

    final verificationId = await widget.store.startPhoneAuth(_phone.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (verificationId == null) {
      setState(() => _error = widget.store.lastError ?? 'Could not send OTP');
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OtpScreen(
          store: widget.store,
          phone: _phone.text,
          verificationId: verificationId,
          usingMock: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              Text(
                'R8',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Find local workers. Chat. Book work.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Text(
                widget.usingMock
                    ? 'MOCK MODE — OTP is always 123456. Configure Firebase for real SMS.'
                    : 'OTP verifies phone control only — not identity verification.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: const InputDecoration(
                  labelText: 'Mobile number',
                  prefixText: '+91 ',
                ),
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
                onPressed: _busy ? null : _continue,
                child: Text(_busy ? 'Sending…' : 'Send OTP'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
