import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'api.dart';          // CHANGÉ
import 'user.dart';         // CHANGÉ : import sur une seule ligne

class Register extends StatefulWidget {
  const Register({super.key});
  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String url = "$baseUrl/register";     // CHANGÉ

  Future<User> register(String email, String password) async {
    final res = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );
    print(res.body);
    if (res.statusCode == 200) {
      return User.fromMap(jsonDecode(res.body));
    } else {
      throw Exception('Failed to register');
    }
  }

  handleRegister() async {
    if (_formKey.currentState == null) return;
    if (_formKey.currentState!.validate()) {
      try {
        User u = await register(_emailController.text, _passwordController.text);
        print(u.email);
        if (!mounted) return;
        Navigator.pop(context);               // retour à l'écran Login
      } catch (e) {
        print(e);   // affiche la vraie erreur dans la console
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not register!', style: TextStyle(fontSize: 16.0)),
          duration: Duration(seconds: 5),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Widget champ(String label, TextEditingController c, {bool cache = false}) {
    return Column(children: [
      Align(
        alignment: Alignment.topLeft,
        child: Text(label, style: GoogleFonts.roboto(fontSize: 30, color: Colors.purple)),
      ),
      TextFormField(
        controller: c,
        obscureText: cache,
        validator: (String? value) {
          if (value == null || value.isEmpty) return '$label is Empty';
          return null;
        },
        style: TextStyle(fontSize: 30, color: Colors.blueGrey.shade700),
        decoration: const InputDecoration(
          errorStyle: TextStyle(fontSize: 20, color: Colors.black),
        ),
      ),
      const SizedBox(height: 40),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(children: [
              Container(
                height: 520,
                width: 340,
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(190, 230, 200, 1),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: const [
                    BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 4))
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(children: [
                    Text("Register",
                        style: GoogleFonts.pacifico(fontSize: 40, color: Colors.white)),
                    champ("Email", _emailController),
                    champ("Password", _passwordController, cache: true),
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: const Text("Already have Account ?",
                          style: TextStyle(
                              fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 90,
                width: 90,
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                  ),
                  onPressed: handleRegister,
                  child: const Icon(Icons.arrow_forward, color: Colors.white, size: 30),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}