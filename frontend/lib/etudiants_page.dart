import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api.dart';
import 'outils.dart';

// Gestion des étudiants : Etudiant (NCE, Nom, Prenom, DateNais, LieuNais, #CodClass)
// On choisit le département, puis la classe, puis on gère ses étudiants.
class EtudiantsPage extends StatefulWidget {
  const EtudiantsPage({super.key});
  @override
  State<EtudiantsPage> createState() => _EtudiantsPageState();
}

class _EtudiantsPageState extends State<EtudiantsPage> {
  List<dynamic> departements = [];
  List<dynamic> classes = [];
  List<dynamic> etudiants = [];
  dynamic selectedDept;   // codDept
  dynamic selectedCode;   // codClass de la classe choisie

  @override
  void initState() {
    super.initState();
    loadDepartements();
  }

  Future<void> loadDepartements() async {
    final res = await http.get(Uri.parse("$baseUrl/departements"));
    if (!mounted) return;
    setState(() => departements = hal(res, "departements"));
  }

  Future<void> loadClasses() async {
    final res = await http.get(
        Uri.parse("$baseUrl/classes/search/findByDepartementCodDept?codDept=$selectedDept"));
    if (!mounted) return;
    setState(() => classes = hal(res, "classes"));
  }

  Future<void> loadEtudiants() async {
    if (selectedCode == null) return;
    final res = await http.get(Uri.parse(
        "$baseUrl/etudiants/search/findByClasseCodClass?codClass=$selectedCode"));
    if (!mounted) return;
    setState(() => etudiants = hal(res, "etudiants"));
  }

  // id == null -> POST (Ajouter) ; sinon -> PATCH (Mettre à jour)
  Future<void> enregistrer(dynamic id, String nom, String prenom, DateTime date, String lieu) async {
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({
      "nom": nom,
      "prenom": prenom,
      "dateNais": date.toIso8601String().substring(0, 10),
      "lieuNais": lieu,
      "classe": "$baseUrl/classes/$selectedCode", // relation = URL de la classe
    });
    final res = id == null
        ? await http.post(Uri.parse("$baseUrl/etudiants"), headers: headers, body: body)
        : await http.patch(Uri.parse("$baseUrl/etudiants/$id"), headers: headers, body: body);
    if (!mounted) return;
    ok(res)
        ? message(context, id == null ? "Étudiant ajouté" : "Étudiant mis à jour")
        : message(context, erreurServeur(res), erreur: true);
    loadEtudiants();
  }

  Future<void> supprimer(dynamic e) async {
    if (!await confirmer(context, "Supprimer l'étudiant ${e["nom"]} ${e["prenom"]} ?")) return;
    final res = await http.delete(Uri.parse("$baseUrl/etudiants/${e["id"]}"));
    if (!mounted) return;
    ok(res)
        ? message(context, "Étudiant supprimé")
        : message(context, "Impossible : l'étudiant a des absences ou des notes", erreur: true);
    loadEtudiants();
  }

  void formulaire({dynamic etudiant}) {
    final nomCtrl = TextEditingController(text: etudiant?["nom"] ?? "");
    final prenomCtrl = TextEditingController(text: etudiant?["prenom"] ?? "");
    final lieuCtrl = TextEditingController(text: etudiant?["lieuNais"] ?? "");
    DateTime date = DateTime.tryParse("${etudiant?["dateNais"] ?? ""}") ?? DateTime(2003, 1, 1);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(etudiant == null ? "Nouvel étudiant" : "Modifier l'étudiant E${etudiant["id"]}"),
          content: Form(
            key: formKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(
                controller: nomCtrl,
                decoration: const InputDecoration(labelText: "Nom"),
                validator: (v) => (v == null || v.trim().isEmpty) ? "Nom obligatoire" : null,
              ),
              TextFormField(
                controller: prenomCtrl,
                decoration: const InputDecoration(labelText: "Prénom"),
                validator: (v) => (v == null || v.trim().isEmpty) ? "Prénom obligatoire" : null,
              ),
              TextFormField(
                controller: lieuCtrl,
                decoration: const InputDecoration(labelText: "Lieu de naissance"),
              ),
              const SizedBox(height: 10),
              Row(children: [
                Text("Né le : ${date.toString().substring(0, 10)}"),
                IconButton(
                  icon: const Icon(Icons.calendar_month),
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: date,
                      firstDate: DateTime(1980),
                      lastDate: DateTime.now(),
                    );
                    if (d != null) setDialogState(() => date = d);
                  },
                ),
              ]),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
            ElevatedButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(context);
                enregistrer(etudiant?["id"], nomCtrl.text.trim(), prenomCtrl.text.trim(), date,
                    lieuCtrl.text.trim());
              },
              child: const Text("Enregistrer"),
            ),
          ],
        ),
      ),
    );
  }

  Widget liste(String label, dynamic value, List<DropdownMenuItem<dynamic>> items,
      void Function(dynamic) onChanged) {
    return Row(children: [
      SizedBox(
          width: 110,
          child: Text("$label :", style: const TextStyle(fontWeight: FontWeight.bold))),
      Expanded(
        child: DropdownButton<dynamic>(
          isExpanded: true,
          hint: const Text("Choisir"),
          value: value,
          items: items,
          onChanged: onChanged,
        ),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage students")),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            liste(
              "Département",
              selectedDept,
              departements
                  .map((d) => DropdownMenuItem<dynamic>(
                      value: d["codDept"], child: Text(d["nomDept"] ?? "")))
                  .toList(),
              (v) {
                setState(() {
                  selectedDept = v;
                  selectedCode = null;
                  classes = [];
                  etudiants = [];
                });
                loadClasses();
              },
            ),
            liste(
              "Classe",
              selectedCode,
              classes
                  .map((c) => DropdownMenuItem<dynamic>(
                      value: c["codClass"], child: Text(c["nomClass"] ?? "")))
                  .toList(),
              (v) {
                setState(() => selectedCode = v);
                loadEtudiants();
              },
            ),
          ]),
        ),
        const Divider(),
        Expanded(
          child: selectedCode == null
              ? const Center(child: Text("Choisissez un département puis une classe"))
              : etudiants.isEmpty
                  ? const Center(child: Text("Aucun étudiant dans cette classe"))
                  : ListView.builder(
                      itemCount: etudiants.length,
                      itemBuilder: (context, i) {
                        final e = etudiants[i];
                        final date = (e["dateNais"] ?? "").toString();
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(child: Text("E${e["id"]}")),
                            title: Text("${e["nom"]} ${e["prenom"]}"),
                            subtitle: Text(
                                "Né le : ${date.length >= 10 ? date.substring(0, 10) : date}"
                                "${(e["lieuNais"] ?? "").toString().isEmpty ? "" : " à ${e["lieuNais"]}"}"),
                            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => formulaire(etudiant: e),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => supprimer(e),
                              ),
                            ]),
                          ),
                        );
                      },
                    ),
        ),
      ]),
      // Le bouton "+" n'apparaît que si une classe est choisie
      floatingActionButton: selectedCode == null
          ? null
          : FloatingActionButton(onPressed: () => formulaire(), child: const Icon(Icons.add)),
    );
  }
}
