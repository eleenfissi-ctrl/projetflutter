import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api.dart';
import 'outils.dart';

// Examen Q1 : absences d'une classe dans une matière donnée, à une date donnée
//   Classe : DSI33   Département : TI
//   Matière : AFCP
//   CHSM : 45 heures                         Date : 24-11-2026
//   Nom | Prenom | NHA
class AbsencesClassePage extends StatefulWidget {
  const AbsencesClassePage({super.key});
  @override
  State<AbsencesClassePage> createState() => _AbsencesClassePageState();
}

class _AbsencesClassePageState extends State<AbsencesClassePage> {
  List<dynamic> departements = [];
  List<dynamic> classes = [];
  List<dynamic> matieres = [];
  dynamic selectedDept;
  dynamic selectedClasse;
  String? selectedMatiere;
  DateTime date = DateTime.now();

  dynamic resultat; // réponse de GET /api/examen/absences
  bool loading = false;

  @override
  void initState() {
    super.initState();
    loadDepartements();
    loadMatieres();
  }

  String isoDate(DateTime d) => d.toIso8601String().substring(0, 10); // 2026-11-24
  String frDate(DateTime d) {
    final p = isoDate(d).split("-");
    return "${p[2]}-${p[1]}-${p[0]}"; // 24-11-2026
  }

  Future<void> loadDepartements() async {
    final res = await http.get(Uri.parse("$baseUrl/departements"));
    if (!mounted) return;
    setState(() => departements = hal(res, "departements"));
  }

  Future<void> loadMatieres() async {
    final res = await http.get(Uri.parse("$baseUrl/matieres"));
    if (!mounted) return;
    setState(() => matieres = hal(res, "matieres"));
  }

  Future<void> loadClasses() async {
    final res = await http.get(
        Uri.parse("$baseUrl/classes/search/findByDepartementCodDept?codDept=$selectedDept"));
    if (!mounted) return;
    setState(() => classes = hal(res, "classes"));
  }

  // Charge le tableau dès que classe + matière + date sont choisies
  Future<void> loadAbsences() async {
    if (selectedClasse == null || selectedMatiere == null) return;
    setState(() => loading = true);
    final res = await http.get(Uri.parse("$baseUrl/api/examen/absences"
        "?codClass=$selectedClasse&codMat=${Uri.encodeComponent(selectedMatiere!)}&date=${isoDate(date)}"));
    if (!mounted) return;
    setState(() {
      loading = false;
      if (ok(res)) {
        resultat = lireJson(res);
      } else {
        resultat = null;
        message(context, erreurServeur(res), erreur: true);
      }
    });
  }

  // Ajouter / Mettre à jour / Supprimer (NHA vide ou 0) l'absence d'un étudiant
  Future<void> saisir(dynamic ligne, double? nha) async {
    final res = await http.put(
      Uri.parse("$baseUrl/api/examen/absences"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "nce": ligne["nce"],
        "codMat": selectedMatiere,
        "dateA": isoDate(date),
        "nha": nha,
      }),
    );
    if (!mounted) return;
    ok(res)
        ? message(context, (nha == null || nha == 0) ? "Absence supprimée" : "Absence enregistrée")
        : message(context, erreurServeur(res), erreur: true);
    loadAbsences();
  }

  void formulaire(dynamic ligne) {
    final nhaCtrl = TextEditingController(text: nombre(ligne["nha"]));
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("${ligne["nom"]} ${ligne["prenom"]}"),
        content: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text("$selectedMatiere le ${frDate(date)}"),
            TextFormField(
              controller: nhaCtrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: "NHA (heures)", helperText: "Laisser vide ou 0 pour supprimer"),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final x = lireNombre(v);
                if (x == null || x < 0) return "Nombre d'heures invalide";
                return null;
              },
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(context);
              saisir(ligne, lireNombre(nhaCtrl.text));
            },
            child: const Text("Enregistrer"),
          ),
        ],
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

  Widget info(String label, String valeur) {
    return Text.rich(TextSpan(children: [
      TextSpan(
          text: "$label : ",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
      TextSpan(text: "$valeur   ", style: const TextStyle(fontSize: 17)),
    ]));
  }

  @override
  Widget build(BuildContext context) {
    final r = resultat;
    final lignes = r == null ? <dynamic>[] : r["lignes"] as List<dynamic>;

    return Scaffold(
      appBar: AppBar(title: const Text("Absences d'une classe")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ----- Choix : Département -> Classe, Matière, Date -----
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
                  selectedClasse = null;
                  classes = [];
                  resultat = null;
                });
                loadClasses();
              },
            ),
            liste(
              "Classe",
              selectedClasse,
              classes
                  .map((c) => DropdownMenuItem<dynamic>(
                      value: c["codClass"], child: Text(c["nomClass"] ?? "")))
                  .toList(),
              (v) {
                setState(() => selectedClasse = v);
                loadAbsences();
              },
            ),
            liste(
              "Matière",
              selectedMatiere,
              matieres
                  .map((m) => DropdownMenuItem<dynamic>(
                      value: m["codMat"], child: Text("${m["codMat"]} - ${m["intMat"]}")))
                  .toList(),
              (v) {
                setState(() => selectedMatiere = v);
                loadAbsences();
              },
            ),
            Row(children: [
              const SizedBox(
                  width: 110,
                  child: Text("Date :", style: TextStyle(fontWeight: FontWeight.bold))),
              Text(frDate(date)),
              IconButton(
                icon: const Icon(Icons.calendar_month),
                onPressed: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (d == null) return;
                  setState(() => date = d);
                  loadAbsences();
                },
              ),
            ]),
            const Divider(height: 32),

            if (loading) const Center(child: CircularProgressIndicator()),

            // ----- Affichage demandé -----
            if (!loading && r != null) ...[
              Center(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Wrap(children: [
                    info("Classe", r["nomClass"] ?? ""),
                    info("Département", r["nomDept"] ?? "-"),
                  ]),
                  info("Matière", r["codMat"] ?? ""),
                  info("CHSM", r["chsm"] == null ? "non définie" : "${nombre(r["chsm"])} heures"),
                ]),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: info("Date", frDate(date)),
              ),
              const SizedBox(height: 6),
              Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    border: TableBorder.all(color: Colors.black54),
                    headingRowColor: WidgetStateProperty.all(Colors.purple.shade50),
                    columns: const [
                      DataColumn(label: Text("Nom", style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text("Prenom", style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text("NHA", style: TextStyle(fontWeight: FontWeight.bold)),
                          numeric: true),
                      DataColumn(label: Text("")),
                    ],
                    rows: lignes
                        .map((l) => DataRow(cells: [
                              DataCell(Text(l["nom"] ?? "")),
                              DataCell(Text(l["prenom"] ?? "")),
                              DataCell(Text(l["nha"] == null ? "" : nombre(l["nha"]))),
                              DataCell(IconButton(
                                icon: Icon(l["nha"] == null ? Icons.add : Icons.edit,
                                    color: Colors.blue),
                                tooltip: "Saisir le NHA",
                                onPressed: () => formulaire(l),
                              )),
                            ]))
                        .toList(),
                  ),
                ),
              ),
              if (lignes.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text("Aucun étudiant dans cette classe", textAlign: TextAlign.center),
                ),
            ],
            if (!loading && r == null)
              const Center(child: Text("Choisissez une classe, une matière et une date")),
          ],
        ),
      ),
    );
  }
}
