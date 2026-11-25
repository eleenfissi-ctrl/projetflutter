import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api.dart';
import 'outils.dart';

// Gestion des utilisateurs : User (id, email, password)
class UsersPage extends StatefulWidget {
  const UsersPage({super.key});
  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  List<dynamic> users = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  Future<void> loadUsers() async {
    final res = await http.get(Uri.parse("$baseUrl/users"));
    if (!mounted) return;
    setState(() {
      users = hal(res, "users");
      loading = false;
    });
  }

  // id == null -> POST (Ajouter) ; sinon -> PUT (Mettre à jour)
  Future<void> enregistrer(dynamic id, String email, String password) async {
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({"email": email, "password": password});
    final res = id == null
        ? await http.post(Uri.parse("$baseUrl/users"), headers: headers, body: body)
        : await http.put(Uri.parse("$baseUrl/users/$id"), headers: headers, body: body);
    if (!mounted) return;
    ok(res)
        ? message(context, id == null ? "Utilisateur ajouté" : "Utilisateur mis à jour")
        : message(context, erreurServeur(res), erreur: true);
    loadUsers();
  }

  Future<void> supprimer(dynamic u) async {
    if (!await confirmer(context, "Supprimer l'utilisateur ${u["email"]} ?")) return;
    final res = await http.delete(Uri.parse("$baseUrl/users/${u["id"]}"));
    if (!mounted) return;
    ok(res) ? message(context, "Utilisateur supprimé") : message(context, erreurServeur(res), erreur: true);
    loadUsers();
  }

  void formulaire({dynamic user}) {
    final emailCtrl = TextEditingController(text: user?["email"] ?? "");
    final passCtrl = TextEditingController(text: user?["password"] ?? "");
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user == null ? "Nouvel utilisateur" : "Modifier l'utilisateur"),
        content: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: "Email"),
              validator: (v) => (v == null || !v.contains("@")) ? "Email invalide" : null,
            ),
            TextFormField(
              controller: passCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Mot de passe"),
              validator: (v) => (v == null || v.isEmpty) ? "Mot de passe obligatoire" : null,
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(context);
              enregistrer(user?["id"], emailCtrl.text.trim(), passCtrl.text);
            },
            child: const Text("Enregistrer"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage users")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, i) {
                final u = users[i];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.person_outline, color: Colors.deepOrange),
                    title: Text(u["email"] ?? ""),
                    subtitle: Text("Id : ${u["id"]}"),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => formulaire(user: u),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => supprimer(u),
                      ),
                    ]),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => formulaire(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
