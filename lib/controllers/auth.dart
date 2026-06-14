import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:goatcheck/models/peternak.dart';
import 'package:goatcheck/main.dart'; 

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;


  
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
      if (context.mounted) {
        _showSnackBar(context, e.message.toString(), Colors.red);
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, "Terjadi kesalahan: ${e.toString()}", Colors.red);
      }
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

  Future<void> logout({required BuildContext context}) async {
    try {
      await _auth.signOut();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, "Gagal keluar: ${e.toString()}", Colors.red);
      }
    }
  }

  Future<void> updateProfile({
    required BuildContext context,
    required String nama,
    required String email,
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    User? user = _auth.currentUser;
    if (user == null) {
      _showSnackBar(context, "Pengguna tidak teridentifikasi", Colors.red);
      return;
    }

    if (nama.trim().isEmpty || email.trim().isEmpty) {
      _showSnackBar(context, "Nama dan email tidak boleh kosong", Colors.orange);
      return;
    }

    bool changingEmail = email.trim() != user.email;
    bool changingPassword = newPassword.isNotEmpty;

    try {
      // 1. Reauthentication is required if changing email or password
      if (changingEmail || changingPassword) {
        if (currentPassword.isEmpty) {
          _showSnackBar(context, "Masukkan password saat ini untuk memverifikasi perubahan sensitif", Colors.orange);
          return;
        }

        // Reauthenticate
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        );
        await user.reauthenticateWithCredential(credential);

        // Update email if requested
        if (changingEmail) {
          await user.updateEmail(email.trim());
        }

        // Update password if requested
        if (changingPassword) {
          if (newPassword != confirmNewPassword) {
            _showSnackBar(context, "Konfirmasi password baru tidak sesuai", Colors.red);
            return;
          }
          if (newPassword.length < 8) {
            _showSnackBar(context, "Password baru minimal 8 huruf", Colors.red);
            return;
          }
          await user.updatePassword(newPassword.trim());
        }
      }

      // 2. Update Firestore document
      Map<String, dynamic> updateData = {
        'nama': nama.trim(),
        'email': email.trim(),
        'updated_at': FieldValue.serverTimestamp(),
      };
      
      if (changingPassword) {
        updateData['password'] = newPassword.trim();
      }

      await _db.collection('peternak').doc(user.uid).update(updateData);

      if (context.mounted) {
        _showSnackBar(context, "Profil berhasil diperbarui!", Colors.green);
      }
    } on FirebaseAuthException catch (e) {
      String message = "Gagal memperbarui profil";
      if (e.code == 'wrong-password') {
        message = "Password saat ini salah";
      } else if (e.code == 'requires-recent-login') {
        message = "Sesi telah berakhir, silakan masuk kembali";
      } else if (e.code == 'email-already-in-use') {
        message = "Email sudah digunakan oleh akun lain";
      } else if (e.code == 'invalid-email') {
        message = "Format email tidak valid";
      } else if (e.code == 'weak-password') {
        message = "Password baru terlalu lemah";
      } else {
        message = e.message ?? message;
      }
      if (context.mounted) {
        _showSnackBar(context, message, Colors.red);
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, "Terjadi kesalahan: ${e.toString()}", Colors.red);
      }
    }
  }
}