import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.userName,
    required this.isDarkMode,
    required this.onSaveName,
    required this.onThemeChanged,
  });

  final String userName;
  final bool isDarkMode;
  final Future<void> Function(String) onSaveName;
  final Future<void> Function(bool) onThemeChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _nameController;
  bool _isSaving = false;
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userName);
    _isDarkMode = widget.isDarkMode;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    setState(() => _isSaving = true);
    try {
      await widget.onSaveName(_nameController.text);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nama berhasil disimpan.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama belum dapat disimpan. Coba lagi.')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pengaturan',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Buat BacaBuku terasa milikmu.',
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Nama dan pilihan tema disimpan di perangkat ini. Akun tidak diperlukan.',
            style: TextStyle(color: colors.onSurfaceVariant, height: 1.4),
          ),
          const SizedBox(height: 28),
          TextField(
            controller: _nameController,
            enabled: !_isSaving,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _saveName(),
            decoration: const InputDecoration(
              labelText: 'Nama panggilan (opsional)',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _isSaving ? null : _saveName,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded),
            label: Text(_isSaving ? 'Menyimpan...' : 'Simpan nama'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 28),
          const Divider(),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Tema gelap'),
            subtitle: const Text('Gunakan tampilan gelap di BacaBuku.'),
            value: _isDarkMode,
            onChanged: (isDark) {
              setState(() => _isDarkMode = isDark);
              widget.onThemeChanged(isDark);
            },
          ),
        ],
      ),
    );
  }
}
