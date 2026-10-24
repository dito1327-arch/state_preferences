import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../providers/user_provider.dart';
import '../widgets/custom_text_field.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _favoriteController = TextEditingController();
  bool _controllersInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Correct lifecycle: inherited dependencies are read here, not in initState.
    final provider = UserProvider.of(context);
    if (!_controllersInitialized && !provider.isLoading) {
      _nameController.text = provider.user.name;
      _emailController.text = provider.user.email;
      _controllersInitialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _favoriteController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    if (RegExp(r'<\s*script\b', caseSensitive: false).hasMatch(name) ||
        name.contains('<') ||
        name.contains('>')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Nama mengandung karakter yang tidak diizinkan.')),
      );
      return;
    }

    final provider = UserProvider.of(context);
    // Exercise 5: simulate email uniqueness using a non-sensitive local list.
    final prefs = await SharedPreferences.getInstance();
    final registeredEmails =
        prefs.getStringList('registered_emails') ?? <String>[];
    final normalizedEmail = email.toLowerCase();
    final currentEmail = provider.user.email.toLowerCase();
    if (registeredEmails.contains(normalizedEmail) &&
        normalizedEmail != currentEmail) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Email sudah digunakan. Gunakan email lain.')),
      );
      return;
    }
    if (!registeredEmails.contains(normalizedEmail)) {
      registeredEmails.add(normalizedEmail);
      await prefs.setStringList('registered_emails', registeredEmails);
    }

    await provider.updateUser(User(
      name: name,
      email: email,
      isLoggedIn: true,
    ));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Profil berhasil disimpan'),
          backgroundColor: Colors.green),
    );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin logout?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Logout', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await UserProvider.of(context).logout();
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _addFavorite() async {
    final item = _favoriteController.text.trim();
    if (item.isEmpty) return;
    await UserProvider.of(context).addFavorite(item);
    _favoriteController.clear();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Favorit ditambahkan jika belum ada.')));
  }

  @override
  Widget build(BuildContext context) {
    final provider = UserProvider.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          if (provider.user.isLoggedIn)
            IconButton(
                icon: const Icon(Icons.logout),
                onPressed: _confirmLogout,
                tooltip: 'Logout'),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    const CircleAvatar(
                        radius: 42,
                        backgroundColor: Colors.deepPurple,
                        child:
                            Icon(Icons.person, size: 52, color: Colors.white)),
                    const SizedBox(height: 24),
                    CustomTextField(
                      controller: _nameController,
                      label: 'Nama',
                      icon: Icons.person,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Nama tidak boleh kosong'
                              : null,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty)
                          return 'Email tidak boleh kosong';
                        if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                            .hasMatch(value.trim()))
                          return 'Format email tidak valid';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _saveProfile,
                      icon: const Icon(Icons.save),
                      label: const Text('Simpan Profil'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16)),
                    ),
                    const SizedBox(height: 24),
                    const Text('Daftar Favorit / Hobi',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                            child: TextField(
                                controller: _favoriteController,
                                decoration: const InputDecoration(
                                    labelText: 'Tambah favorit',
                                    border: OutlineInputBorder()))),
                        const SizedBox(width: 8),
                        IconButton.filled(
                            onPressed: _addFavorite,
                            icon: const Icon(Icons.add),
                            tooltip: 'Tambah favorit'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (provider.favorites.isEmpty)
                      const Text('Belum ada favorit.')
                    else
                      ...provider.favorites.map((favorite) => Card(
                            child: ListTile(
                              leading: const Icon(Icons.favorite,
                                  color: Colors.pink),
                              title: Text(favorite),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                tooltip: 'Hapus favorit',
                                onPressed: () =>
                                    provider.removeFavorite(favorite),
                              ),
                            ),
                          )),
                    const SizedBox(height: 16),
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Icon(Icons.info_outline),
                              SizedBox(width: 8),
                              Text('Catatan Keamanan',
                                  style: TextStyle(fontWeight: FontWeight.bold))
                            ]),
                            SizedBox(height: 8),
                            Text(
                                'Data profil dan preferensi disimpan di SharedPreferences tanpa enkripsi. Jangan simpan password, PIN, atau data sensitif di sini.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
