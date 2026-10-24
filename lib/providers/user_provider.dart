import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';

/// InheritedWidget used by descendants to read shared application state.
class UserProvider extends InheritedWidget {
  final User user;
  final bool isLoading;
  final bool isDarkMode;
  final int visitCount;
  final List<String> favorites;
  final Future<void> Function(User) updateUser;
  final Future<void> Function() logout;
  final Future<void> Function(bool) setDarkMode;
  final Future<void> Function(String) addFavorite;
  final Future<void> Function(String) removeFavorite;

  const UserProvider({
    super.key,
    required this.user,
    required this.isLoading,
    required this.isDarkMode,
    required this.visitCount,
    required this.favorites,
    required this.updateUser,
    required this.logout,
    required this.setDarkMode,
    required this.addFavorite,
    required this.removeFavorite,
    required super.child,
  });

  static UserProvider of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<UserProvider>();
    assert(provider != null, 'UserProvider tidak ditemukan di context');
    return provider!;
  }

  @override
  bool updateShouldNotify(UserProvider oldWidget) =>
      oldWidget.user != user ||
      oldWidget.isLoading != isLoading ||
      oldWidget.isDarkMode != isDarkMode ||
      oldWidget.visitCount != visitCount ||
      !_sameList(oldWidget.favorites, favorites);

  static bool _sameList(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Owns state and persists non-sensitive preferences locally.
class UserProviderWrapper extends StatefulWidget {
  final Widget child;
  const UserProviderWrapper({super.key, required this.child});

  @override
  State<UserProviderWrapper> createState() => _UserProviderWrapperState();
}

class _UserProviderWrapperState extends State<UserProviderWrapper> {
  User _user = const User(name: '', email: '');
  bool _isLoading = true;
  bool _isDarkMode = false;
  int _visitCount = 0;
  List<String> _favorites = [];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final nextVisitCount = (prefs.getInt('visit_count') ?? 0) + 1;
      await prefs.setInt('visit_count', nextVisitCount);
      if (!mounted) return;
      setState(() {
        _user = User(
          name: prefs.getString('user_name') ?? '',
          email: prefs.getString('user_email') ?? '',
          isLoggedIn: prefs.getBool('is_logged_in') ?? false,
        );
        _isDarkMode = prefs.getBool('is_dark_mode') ?? false;
        _visitCount = nextVisitCount;
        _favorites = prefs.getStringList('favorites') ?? <String>[];
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateUser(User newUser) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', newUser.name);
    await prefs.setString('user_email', newUser.email);
    await prefs.setBool('is_logged_in', newUser.isLoggedIn);
    if (!mounted) return;
    setState(() => _user = newUser);
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_name');
    await prefs.setBool('is_logged_in', false);
    if (!mounted) return;
    setState(() => _user = _user.copyWith(name: '', isLoggedIn: false));
  }

  Future<void> _setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', value);
    if (!mounted) return;
    setState(() => _isDarkMode = value);
  }

  Future<void> _addFavorite(String value) async {
    final item = value.trim();
    if (item.isEmpty ||
        _favorites.any((e) => e.toLowerCase() == item.toLowerCase())) return;
    final next = [..._favorites, item];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', next);
    if (!mounted) return;
    setState(() => _favorites = next);
  }

  Future<void> _removeFavorite(String value) async {
    final next = _favorites.where((e) => e != value).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', next);
    if (!mounted) return;
    setState(() => _favorites = next);
  }

  @override
  Widget build(BuildContext context) => UserProvider(
        user: _user,
        isLoading: _isLoading,
        isDarkMode: _isDarkMode,
        visitCount: _visitCount,
        favorites: List.unmodifiable(_favorites),
        updateUser: _updateUser,
        logout: _logout,
        setDarkMode: _setDarkMode,
        addFavorite: _addFavorite,
        removeFavorite: _removeFavorite,
        child: widget.child,
      );
}
