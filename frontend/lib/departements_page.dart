import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api.dart';
import 'outils.dart';

// Gestion des départements : Département (CodDept, NomDept)
class DepartementsPage extends StatefulWidget {
  const DepartementsPage({super.key});
  @override
  State<DepartementsPage> createState() => _DepartementsPageState();
}

class _DepartementsPageState extends State<DepartementsPage> {
  List<dynamic> departements = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadDepartements();
  }

  Future<void> loadDepartements() async {
    final res = await http.get(Uri.parse("$baseUrl/departements"));
    if (!mounted) return;
    setState(() {
      departements = hal(res, "departements");
      loading = false;
    });
  }

  // id == null -> POST (Ajouter) ; sinon -> PUT (Mettre à jour)
  Future<void> enregistrer(dynamic id, String nom) async {
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({"nomDept": nom});
    final res = id == null
        ? await http.post(Uri.parse("$baseUrl/departements"), headers: headers, body: body)
        : await http.put(Uri.parse("$baseUrl/departements/$id"), headers: headers, body: body);
    if (!mounted) return;
    ok(res)
        ? message(context, id == null ? "Département ajouté" : "Département mis à jour")
        : message(context, erreurServeur(res), erreur: true);
    loadDepartements();
  }

  Future<void> supprimer(dynamic d) async {
    if (!await confirmer(context, "Supprimer le département ${d["nomDept"]} ?")) return;
    final res = await http.delete(Uri.parse("$baseUrl/departements/${d["codDept"]}"));
    if (!mounted) return;
    ok(res)
        ? message(context, "Département supprimé")
        : message(context, "Impossible : ce département contient des classes", erreur: true);
    loadDepartements();
  }

  void formulaire({dynamic dept}) {
    final nomCtrl = TextEditingController(text: dept?["nomDept"] ?? "");
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(dept == null ? "Nouveau département" : "Modifier le département"),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: nomCtrl,
            decoration: const InputDecoration(labelText: "Nom (ex : TI)"),
            validator: (v) => (v == null || v.trim().isEmpty) ? "Nom obligatoire" : null,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(context);
              enregistrer(dept?["codDept"], nomCtrl.text.trim());
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
      appBar: AppBar(title: const Text("Manage departments")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: departements.length,
              itemBuilder: (context, i) {
                final d = departements[i];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.apartment, color: Colors.deepOrange),
                    title: Text(d["nomDept"] ?? ""),
                    subtitle: Text("Code : ${d["codDept"]}"),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => formulaire(dept: d),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => supprimer(d),
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
