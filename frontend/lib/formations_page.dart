import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api.dart';

class FormationsPage extends StatefulWidget {
  const FormationsPage({super.key});
  @override
  State<FormationsPage> createState() => _FormationsPageState();
}

class _FormationsPageState extends State<FormationsPage> {
  List<dynamic> formations = [];

  @override
  void initState() {
    super.initState();
    loadFormations();
  }

  Future<void> loadFormations() async {
    final res = await http.get(Uri.parse("$baseUrl/formations"));
    final data = jsonDecode(res.body);
    setState(() => formations = data["_embedded"]["formations"]);
  }

  Future<void> addFormation(String nom, int duree) async {
    await http.post(
      Uri.parse("$baseUrl/formations"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"nom": nom, "duree": duree}),
    );
    loadFormations();
  }

  Future<void> deleteFormation(dynamic id) async {
    final res = await http.delete(Uri.parse("$baseUrl/formations/$id"));
    if (res.statusCode >= 400 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Impossible : des étudiants suivent cette formation"),
        backgroundColor: Colors.red,
      ));
    }
    loadFormations();
  }

  void showAddDialog() {
    final nomCtrl = TextEditingController();
    final dureeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Nouvelle formation"),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nomCtrl, decoration: const InputDecoration(labelText: "Nom")),
          TextField(
            controller: dureeCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Durée"),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () {
              addFormation(nomCtrl.text, int.tryParse(dureeCtrl.text) ?? 0);
              Navigator.pop(context);
            },
            child: const Text("Ajouter"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage trainings")),
      body: ListView.builder(
        itemCount: formations.length,
        itemBuilder: (context, i) {
          final f = formations[i];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.menu_book, color: Colors.deepOrange),
              title: Text(f["nom"] ?? ""),
              subtitle: Text("Durée : ${f["duree"]}"),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => deleteFormation(f["id"]),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}