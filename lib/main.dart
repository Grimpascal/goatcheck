import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:goatcheck/controllers/auth.dart';
import 'package:goatcheck/views/Register.dart';
import 'package:goatcheck/views/dashboard.dart';
import 'package:goatcheck/views/lupaPassword.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:goatcheck/services/background_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyCBwX6dYLD5jGkA3XU1GKm2DF7Tn8I7cjM", 
        appId: "1:608287258205:android:a047e0f3fa5fa30769ffb4",       
        messagingSenderId: "...",
        projectId: "goatcheck-ppl",
      ),
    );
    await MyBackgroundService.initializeService();
  } catch (e) {
    print("Firebase init error: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final Stream<User?> _authStateStream;

  @override
  void initState() {
    super.initState();
    _authStateStream = FirebaseAuth.instance.authStateChanges();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "GoatCheck",
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFEFFFC8)),
      ),
      home: StreamBuilder<User?>(
        stream: _authStateStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Colors.black),
              ),
            );
          }
          if (snapshot.hasData) {
            return const dashboard();
          }
          return const LoginPage();
        },
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscureText = true;
  bool _rememberMe = false;

  late AuthController _authController;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose(){
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState(){
    super.initState();
    _authController = AuthController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFFFC8),
      body: Stack(
        children: [
          Positioned(
            top: 50,
            left: -50,
            child: Opacity(
              opacity: 0.2,
              child: Icon(
                Icons.cruelty_free,
                size: 300,
                color: Colors.green.shade300,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 100), 
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(fontSize: 32, color: Color(0xFF3B341F)),
                      children: [
                        TextSpan(text: 'Selamat Datang\n'),
                        TextSpan(text: 'Di '),
                        TextSpan(
                          text: 'GOATCheck',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 60),
                  const Text("Masukkan akun anda untuk melanjutkan", 
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 20),
                  
                  
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      hintText: 'email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: _passwordController,
                    obscureText: _obscureText,
                    decoration: InputDecoration(
                      hintText: 'password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscureText = !_obscureText),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.5),
                    ),
                  ),

                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (val) => setState(() => _rememberMe = val!),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          ),
                          const Text("Ingat saya"),
                        ],
                      ),
                      TextButton(
                        onPressed: () {Navigator.push(context, MaterialPageRoute(builder: (context) => const lupaPassword()));},
                        child: const Text("lupa password?", 
                          style: TextStyle(decoration: TextDecoration.underline, color: Colors.black)),
                          
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        _authController.login(
                          context: context,
                          email: _emailController.text,
                          password: _passwordController.text,
                          targetPage: const dashboard());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF85CB33 ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.login, color: Colors.black),
                          SizedBox(width: 10),
                          Text("Masuk", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                 
                  Center(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(color: Colors.black),
                        children: [
                          TextSpan(text: "Belum memiliki akun? "),
                          TextSpan(
                            text: "Mendaftar",
                            style: TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                            recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const Register())
                              );
                            }
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}