import 'package:flutter/material.dart';

import '../../../core/settings/app_settings.dart';

/// Lets the operator point the app at a Laravel API base on first launch.
/// Saving an empty string falls back to the in-memory mock repository.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.settings,
    required this.onSaved,
  });

  final AppSettings settings;
  final VoidCallback onSaved;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _baseCtrl;
  bool _signingOut = false;

  @override
  void initState() {
    super.initState();
    _baseCtrl = TextEditingController(text: widget.settings.apiBase);
  }

  @override
  void dispose() {
    _baseCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final raw = _baseCtrl.text.trim();
    await widget.settings.setApiBase(raw);
    if (!mounted) return;
    widget.onSaved();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(raw.isEmpty
            ? 'Cleared API base. App will use the local demo data.'
            : 'API base saved.'),
      ),
    );
  }

  Future<void> _signOut() async {
    setState(() => _signingOut = true);
    await widget.settings.clearTokens();
    if (!mounted) return;
    setState(() => _signingOut = false);
    widget.onSaved();
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final hasToken = widget.settings.accessToken != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'TricyKab API base',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _baseCtrl,
            decoration: const InputDecoration(
              hintText: 'http://10.0.2.2:8000/api/v1',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 8),
          const Text(
            'Use http://10.0.2.2:8000/api/v1 for the Android emulator on a host running Laravel.\n'
            'Use http://<lan-ip>:8000/api/v1 on physical devices on the same Wi-Fi.\n'
            'Leave empty to fall back to the in-app demo (no backend).',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('Save'),
          ),
          const Divider(height: 32),
          const Text(
            'Auth session',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(hasToken ? 'Signed in (token cached locally)' : 'Not signed in.'),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: hasToken && !_signingOut ? _signOut : null,
            icon: const Icon(Icons.logout),
            label: Text(_signingOut ? 'Signing out...' : 'Sign out / clear token'),
          ),
        ],
      ),
    );
  }
}
