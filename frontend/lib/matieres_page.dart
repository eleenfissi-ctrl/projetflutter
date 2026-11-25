import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api.dart';
import 'outils.dart';

// Gestion des matières : Matière (CodMat, IntMat, Description)
class MatieresPage extends StatefulWidget {
  const MatieresPage({super.key});
  @override
  State<MatieresPage> createState() => _MatieresPageState();
}

class _MatieresPageState extends State<MatieresPage> {
  List<dynamic> matieres = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadMatieres();
  }

  Future<void> loadMatieres() async {
    final res = await http.get(Uri.parse("$baseUrl/matieres"));
    if (!mounted) return;
    setState(() {
      matieres = hal(res, "matieres");
      loading = false;
    });
  }

  // Le code matière (AFCP, SOA...) est saisi à la main : c'est la clé.
  // Ajouter et Mettre à jour utilisent donc tous les deux PUT /matieres/{codMat}.
  Future<void> enregistrer(String codMat, String intitule, String description, bool nouveau) async {
    if (nouveau && matieres.any((m) => m["codMat"] == codMat)) {
      message(context, "La matière $codMat existe déjà", erreur: true);
      return;
    }
    final res = await http.put(
      Uri.parse("$baseUrl/matieres/${Uri.encodeComponent(codMat)}"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"codMat": codMat, "intMat": intitule, "description": description}),
    );
    if (!mounted) return;
    ok(res)
        ? message(context, nouveau ? "Matière ajoutée" : "Matière mise à jour")
        : message(context, erreurServeur(res), erreur: true);
    loadMatieres();
  }

  Future<void> supprimer(dynamic m) async {
    if (!await confirmer(context, "Supprimer la matière ${m["codMat"]} ?")) return;
    final res = await http.delete(Uri.parse("$baseUrl/matieres/${Uri.encodeComponent(m["codMat"])}"));
    if (!mounted) return;
    ok(res)
        ? message(context, "Matière supprimée")
        : message(context, "Impossible : la matière a des absences, des notes ou des classes",
            erreur: true);
    loadMatieres();
  }

  void formulaire({dynamic matiere}) {
    final codeCtrl = TextEditingController(text: matiere?["codMat"] ?? "");
    final intCtrl = TextEditingController(text: matiere?["intMat"] ?? "");
    final descCtrl = TextEditingController(text: matiere?["description"] ?? "");
    final formKey = GlobalKey<FormState>();
    final nouveau = matiere == null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(nouveau ? "Nouvelle matière" : "Modifier la matière"),
        content: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              controller: codeCtrl,
              enabled: nouveau, // la clé ne se modifie pas
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: "Code (ex : AFCP)"),
              validator: (v) => (v == null || v.trim().isEmpty) ? "Code obligatoire" : null,
            ),
            TextFormField(
              controller: intCtrl,
              decoration: const InputDecoration(labelText: "Intitulé"),
              validator: (v) => (v == null || v.trim().isEmpty) ? "Intitulé obligatoire" : null,
            ),
            TextFormField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: "Description"),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(context);
              enregistrer(codeCtrl.text.trim().toUpperCase(), intCtrl.text.trim(),
                  descCtrl.text.trim(), nouveau);
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
      appBar: AppBar(title: const Text("Manage subjects")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: matieres.length,
              itemBuilder: (context, i) {
                final m = matieres[i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(m["codMat"] ?? "", style: const TextStyle(fontSize: 10)),
                    ),
                    title: Text(m["intMat"] ?? ""),
                    subtitle: Text(m["description"] ?? ""),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => formulaire(matiere: m),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => supprimer(m),
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
