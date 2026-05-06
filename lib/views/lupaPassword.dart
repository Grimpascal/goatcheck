import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:goatcheck/controllers/auth.dart';
import 'package:goatcheck/views/Register.dart';

class lupaPassword extends StatefulWidget {
  const lupaPassword({super.key});

    @override
    Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFEFFFC8))
      ),
    );
  }

  @override
  State<lupaPassword> createState() => _lupaPasswordState();
}

class _lupaPasswordState extends State<lupaPassword> {

  final TextEditingController _emailController = TextEditingController();

  late AuthController _authController;

  @override
    void initState() {
      super.initState();
      _authController = AuthController(); 
    }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
    Widget build(BuildContext context){
      return Scaffold(
        backgroundColor: Color(0xFFEFFFC8),
        appBar: AppBar(
          backgroundColor: Color(0xFFEFFFC8),
          centerTitle: false,
          title: Text("Kembali"),
        ),
        body: Padding(
          padding: const EdgeInsetsGeometry.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text(
                "Lupa Password",
                style: TextStyle(
                  fontSize: 33,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF3B341F)
                ),
              ),

              const SizedBox(height: 10),
              const Text(
                "Masukkan email yang terdaftar untuk mengatur ulang kata sandi anda",
                style: TextStyle(
                  color: Color(0xFF3B341F)
                ),
              ),

              const SizedBox(height: 20),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: "Email",
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.5)
                ),
              ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: (){
                    _authController.resetPassword(context: context, email: _emailController.text.trim());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF85CB33),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(12))
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send_outlined, color: Colors.black),
                      SizedBox(width: 10,),
                      Text(
                        "Kirim Link Reset",
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  )
                ),
              ),

              const SizedBox(height: 20),
              Center(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      color: Colors.black
                    ),
                    children: [
                      TextSpan(
                        text: "Belum memiliki akun? "
                      ),
                      TextSpan(
                        text: "Mendaftar",
                        style: TextStyle(
                          color: Color(0xFF3B341F),
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const Register()));
                        }
                      ),
                    ]
                  )
                ),
              )
            ],
          ),
          ),
      );
    }
}