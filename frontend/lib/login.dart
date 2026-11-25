import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'api.dart';          // CHANGÉ
import 'user.dart';         // CHANGÉ : minuscule
import 'register.dart';
import 'dashboard.dart';

class Login extends StatefulWidget {
  const Login({super.key});
  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  // 1) Déclarations
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String url = "$baseUrl/login";        // CHANGÉ

  // 2) Appel HTTP
  Future<User> save(String email, String password) async {
    var res = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );
    print(res.body);
    if (res.statusCode == 200) {
      return User.fromMap(jsonDecode(res.body));
    } else {
      throw Exception('Failed to login.');
    }
  }

  handleSignIn() async {
    if (_formKey.currentState == null) return;
    if (_formKey.currentState!.validate()) {
      try {
        User u = await save(_emailController.text, _passwordController.text);
        print(u.email);
        if (!mounted) return;
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const Dashboard()));
      } catch (e) {
        print(e);   // affiche la vraie erreur dans la console
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not log in with these credentials!',
              style: TextStyle(fontSize: 16.0)),
          duration: Duration(seconds: 5),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  // 3) Interface
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 520, width: 340,
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(190, 230, 200, 1),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 4))],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(children: [
                      Text("Login", style: GoogleFonts.oswald(
                          fontWeight: FontWeight.w700, fontSize: 50, color: Colors.black45)),
                      Align(alignment: Alignment.topLeft,
                          child: Text("Email", style: GoogleFonts.roboto(fontSize: 30, color: Colors.purple))),
                      TextFormField(
                        controller: _emailController,
                        validator: (String? value) {
                          if (value == null || value.isEmpty) return 'Email is Empty';
                          return null;
                        },
                        style: TextStyle(fontSize: 30, color: Colors.blueGrey.shade700),
                        decoration: const InputDecoration(
                          errorStyle: TextStyle(fontSize: 20, color: Colors.black),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 50),
                      Align(alignment: Alignment.topLeft,
                          child: Text("Password", style: GoogleFonts.roboto(fontSize: 30, color: Colors.purple))),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        validator: (String? value) {
                          if (value == null || value.isEmpty) return 'Password is Empty';
                          return null;
                        },
                        style: TextStyle(fontSize: 30, color: Colors.blueGrey.shade700),
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 30),
                      Center(
                        child: InkWell(
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (context) => const Register())),
                          child: const Text("Dont have Account ?",
                              style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 90, width: 90,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(233, 65, 82, 1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                    ),
                    onPressed: handleSignIn,
                    child: const Icon(Icons.arrow_forward, color: Colors.white, size: 30),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}