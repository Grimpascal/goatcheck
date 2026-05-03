import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
// Pastikan path import model ini benar sesuai folder kamu
import 'package:goatcheck/models/peternak.dart';
import 'package:goatcheck/services/auth_service.dart'; 

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  // FUNGSI REGISTER
  Future<void> register({
    required BuildContext context,
    required String nama,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    if (password != confirmPassword) {
      _showSnackBar(context, "Password tidak cocok!", Colors.red);
      return;
    }

    if (password.length < 8) {
      _showSnackBar(context, "Password minimal 8 huruf", Colors.red);
      return;
    }

    try {
      // 1. Buat User di Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // 2. Gunakan MODEL untuk menyusun data
      PeternakModel peternak = PeternakModel(
        uid: userCredential.user!.uid,
        nama: nama.trim(),
        email: email.trim(),
        password: password.trim(), // Sinkronisasi manual sesuai request kamu
      );

      // 3. Simpan ke Firestore menggunakan toMap() dari Model
      await _db.collection('peternak').doc(peternak.uid).set(peternak.toMap());

      if (context.mounted) {
        _showSnackBar(context, "Akun berhasil dibuat! Silakan masuk.", Colors.green);
        Future.delayed(const Duration(seconds: 2), () {
          if (context.mounted) Navigator.pop(context);
        });
      }
    } on FirebaseAuthException catch (e) {
      // Solusi Error JavaScript: Paksa ambil message sebagai String
      _showSnackBar(context, e.message.toString(), Colors.red);
    } catch (e) {
      // Menangkap error umum agar tidak crash di web
      _showSnackBar(context, "Terjadi kesalahan: ${e.toString()}", Colors.red);
    }
  }

  // FUNGSI LOGIN
Future<void> login({
  required BuildContext context,  
  required String email,
  required String password,
  required Widget targetPage,
}) async {
  try {
    // Proses login
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    
    // Navigasi jika berhasil
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => targetPage),
        (route) => false,
      );
    }
  } catch (e) {
    // PAKSA ke String untuk menghindari error tipe data JS di Web
    String errorMessage = "Email atau password salah";
    String errorString = e.toString();
    
    if (errorString.contains('network-request-failed')) {
      errorMessage = "Koneksi internet bermasalah";
    }
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    }
  }
}

  void _handleError(BuildContext context, Object e) {
    String message = "Terjadi kesalahan";
    if (e.toString().contains('wrong-password')) {
      message = "Password salah";
    } else if (e.toString().contains('user-not-found')) {
      message = "Email tidak ditemukan";
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // Helper SnackBar agar tidak duplikasi kode
  void _showSnackBar(BuildContext context, String message, Color color) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message), 
        backgroundColor: color, 
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}