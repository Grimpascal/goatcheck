import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:goatcheck/views/main.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  Widget build(BuildContext context){
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFEFFFC8))
      ),
    );
  }

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  bool _tutupSandi = true;
  bool _tutupUlangSandi = true;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  Future<void> _register() async {

    String password = _passwordController.text.trim();

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password tidak cocok!")),
      );
      return;
    }

    if(password.length < 8){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password minimal 8 huruf"), backgroundColor: Colors.red),
      );
      return;
    }

    try{
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim());

        await FirebaseFirestore.instance.collection('peternak').doc(userCredential.user!.uid).set({
          'nama': _namaController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp()
        });
        if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Akun berhasil dibuat! Silakan masuk."),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
          Future.delayed(const Duration(seconds: 2), () {
          Navigator.pop(context); // Kembali ke halaman Login
        });
      }
      }on FirebaseAuthException catch(e){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? "Terjadi kesalahan"))
        );
      }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFEFFFC8),
      appBar: AppBar(
        backgroundColor: Color(0xFFEFFFC8),
        centerTitle: false,
        title: const Text("Kembali"),
        ),
        body: SafeArea(
          child: Padding(
            padding:  const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const SizedBox(height: 40,),
                const Text(
                  "Mendaftar",
                  style: TextStyle(
                    fontSize: 33,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF3B341F)
                  ),
                ),

                const SizedBox(height: 10),
                const Text(
                  "Isi data dibawah untuk membuat akun baru"
                  ),

                const SizedBox(height: 60),
                TextField(
                  controller: _namaController,
                  decoration: InputDecoration(
                    hintText: "Nama",
                    prefixIcon: const Icon(Icons.account_circle_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.5)
                  ),
                ),

                const SizedBox(height: 20),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.email_outlined),
                    hintText: "Email",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.5)
                  ),
                ),

                const SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  obscureText: _tutupSandi,
                  decoration: InputDecoration(
                    hintText: "Password",
                    prefixIcon: Icon(Icons.lock_outline),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.5),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    suffixIcon: IconButton(
                      icon: Icon(_tutupSandi ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _tutupSandi = !_tutupSandi),
                      ),
                  ),
                ),

                const SizedBox(height: 20),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: _tutupUlangSandi,
                  decoration: InputDecoration(
                    hintText: "Ulangi Password",
                    prefixIcon: const Icon(Icons.lock_reset),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.5),
                    suffixIcon: IconButton(
                      icon: Icon(_tutupUlangSandi ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _tutupUlangSandi = !_tutupUlangSandi),
                  ),
                ),
                ),

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF85CB33),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(12))
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_add_alt_1_outlined, color: Colors.black,),
                        SizedBox(width: 10),
                        Text("Daftar",
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    )),
                ),

                const SizedBox(height: 30),
                Center(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(color: Colors.black),
                      children: [
                        TextSpan(text: "Sudah memiliki akun? "),
                        TextSpan(
                          text: "Masuk",
                          style: TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                          recognizer: TapGestureRecognizer()
                          ..onTap = (){
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const MyApp()));
                          }
                        ),
                      ],
                    )
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }
}