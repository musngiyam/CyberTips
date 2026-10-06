import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _client = Supabase.instance.client;

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Returns null on success, or an error message string on failure.
  Future<String?> register(String username, String password) async {
    final trimmedUsername = username.trim();
    if (trimmedUsername.isEmpty || password.isEmpty) {
      return "Username and password can't be empty.";
    }

    // Check if username already exists
    final existing = await _client
        .from('users')
        .select('username')
        .eq('username', trimmedUsername)
        .maybeSingle();

    if (existing != null) {
      return "That username is already taken.";
    }

    final hashedPassword = _hashPassword(password);

    try {
      await _client.from('users').insert({
        'username': trimmedUsername,
        'password': hashedPassword,
      });
      return null; // success
    } catch (e) {
      return "Registration failed. Please try again.";
    }
  }

  /// Returns null on success, or an error message string on failure.
  Future<String?> login(String username, String password) async {
    final trimmedUsername = username.trim();
    if (trimmedUsername.isEmpty || password.isEmpty) {
      return "Username and password can't be empty.";
    }

    final hashedPassword = _hashPassword(password);

    final result = await _client
        .from('users')
        .select('username, password')
        .eq('username', trimmedUsername)
        .maybeSingle();

    if (result == null) {
      return "No account found with that username.";
    }

    if (result['password'] != hashedPassword) {
      return "Incorrect password.";
    }

    return null; // success
  }
}
