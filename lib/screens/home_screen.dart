import 'package:flutter/material.dart';

import '../providers/user_provider.dart';
import 'profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = UserProvider.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          IconButton(
            tooltip: provider.isDarkMode
                ? 'Aktifkan mode terang'
                : 'Aktifkan mode gelap',
            icon:
                Icon(provider.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => provider.setDarkMode(!provider.isDarkMode),
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.home, size: 80, color: Colors.deepPurple),
                    const SizedBox(height: 20),
                    Text(
                      provider.user.isLoggedIn
                          ? 'Selamat datang, ${provider.user.name}!'
                          : 'Selamat datang, Tamu!',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (provider.user.isLoggedIn) ...[
                      const SizedBox(height: 8),
                      Text('Email: ${provider.user.email}'),
                    ],
                    const SizedBox(height: 12),
                    Chip(
                        label: Text(
                            'Aplikasi dibuka ${provider.visitCount} kali')),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ProfileScreen()),
                      ),
                      icon: Icon(provider.user.isLoggedIn
                          ? Icons.person
                          : Icons.login),
                      label: Text(provider.user.isLoggedIn
                          ? 'Lihat Profil'
                          : 'Login / Daftar'),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      child: SwitchListTile(
                        title: const Text('Mode gelap'),
                        subtitle:
                            const Text('Preferensi disimpan di perangkat'),
                        value: provider.isDarkMode,
                        onChanged: provider.setDarkMode,
                        secondary: const Icon(Icons.dark_mode),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
