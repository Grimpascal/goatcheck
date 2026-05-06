import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:goatcheck/models/peternak.dart';
import 'package:goatcheck/services/auth_service.dart'; 

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  
Future<void> register({
    required BuildContext context,
    required String nama,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    
    if (nama.trim().isEmpty || 
        email.trim().isEmpty || 
        password.trim().isEmpty || 
        confirmPassword.trim().isEmpty) {
      _showSnackBar(context, "Tolong lengkapi data anda", Colors.orange);
      return;
    }

    
    if (password != confirmPassword) {
      _showSnackBar(context, "Konfirmasi password tidak sesuai", Colors.red);
      return;
    }

    
    if (password.length < 8) {
      _showSnackBar(context, "Password minimal 8 huruf", Colors.red);
      return;
    }

    try {
      
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      
      PeternakModel peternak = PeternakModel(
        uid: userCredential.user!.uid,
        nama: nama.trim(),
        email: email.trim(),
        password: password.trim(), 
      );

      
      await _db.collection('peternak').doc(peternak.uid).set(peternak.toMap());

      if (context.mounted) {
        _showSnackBar(context, "Akun berhasil dibuat! Silakan masuk.", Colors.green);
        Future.delayed(const Duration(seconds: 2), () {
          if (context.mounted) Navigator.pop(context);
        });
      }
    } on FirebaseAuthException catch (e) {
      
      _showSnackBar(context, e.message.toString(), Colors.red);
    } catch (e) {
      
      _showSnackBar(context, "Terjadi kesalahan: ${e.toString()}", Colors.red);
    }
  }

  
Future<void> login({
  required BuildContext context,  
  required String email,
  required String password,
  required Widget targetPage,
}) async {
  if (email.trim().isEmpty || password.trim().isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Tolong lengkapi data anda"), 
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return;
  }
  try {
    
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    
    
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => targetPage),
        (route) => false,
      );
    }
  } catch (e) {
    
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
Future<void> resetPassword({
    required BuildContext context,
    required String email,
  }) async {
    
    if (email.trim().isEmpty) {
      _showSnackBar(context, "Masukkan email terlebih dahulu", Colors.orange);
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      
      if (context.mounted) {
        _showSnackBar(context, "Link reset telah dikirim ke email anda", Colors.green);
      }
    } on FirebaseAuthException catch (e) {
      String message = "Terjadi kesalahan";
      
      
      if (e.code == 'user-not-found') {
        message = "Email tidak terdaftar dalam sistem";
      } else if (e.code == 'invalid-email') {
        message = "Format email tidak valid";
      }

      if (context.mounted) {
        _showSnackBar(context, message, Colors.red);
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, "Error: ${e.toString()}", Colors.red);
      }
    }
  }
}