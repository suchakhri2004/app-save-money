import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// Stream ที่คอย listen การเปลี่ยนแปลงของ auth state
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// Provider ที่บอกว่า user login อยู่หรือเปล่า
final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authServiceProvider).currentUser != null;
});

// Provider ข้อมูล user ปัจจุบัน
final currentUserProvider = Provider<User?>((ref) {
  ref.watch(authStateProvider); // re-evaluate เมื่อ auth เปลี่ยน
  return ref.watch(authServiceProvider).currentUser;
});
