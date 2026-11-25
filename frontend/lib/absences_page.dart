import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api.dart';
import 'total_absences_page.dart';
import 'moyennes_page.dart';

class AbsencesPage extends StatefulWidget {
  const AbsencesPage({super.key});

  @override
  State<AbsencesPage> createState() => _AbsencesPageState();
}

class _AbsencesPageState extends State<AbsencesPage> {
  // Contenu des listes
  List<dynamic> departements = [];
  List<dynamic> classes = [];
  List<dynamic> etudiants = [];
  List<dynamic> matieres = [];
  List<dynamic> absences = [];

  // Sélections : on garde seulement les identifiants
  dynamic selectedDept;      // codDept
  dynamic selectedClasse;    // codClass
  dynamic selectedEtudiant;  // id (= NCE)

  // Zones de texte Nom / Prénom
  final nomCtrl = TextEditingController();
  final prenomCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadDepartements();
    loadMatieres();
  }

  @override
  void dispose() {
    nomCtrl.dispose();
    prenomCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------
  // Outils
  // ---------------------------------------------------------------

  // Spring Data REST répond au format HAL : {"_embedded": {"cle": [...]}}
  List<dynamic> hal(String body, String cle) {
    final data = jsonDecode(body);
    return data["_embedded"]?[cle] ?? [];
  }

  String isoDate(DateTime d) => d.toIso8601String().substring(0, 10); // 2025-11-11

  String frDate(String iso) {
    final p = iso.split("-");
    return "${p[2]}-${p[1]}-${p[0]}"; // 11-11-2025
  }

  void message(String texte, Color couleur) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texte), backgroundColor: couleur),
    );
  }

  // ---------------------------------------------------------------
  // Chargement des listes
  // ---------------------------------------------------------------

  Future<void> loadDepartements() async {
    final res = await http.get(Uri.parse("$baseUrl/departements"));
    if (!mounted) return;
    setState(() => departements = hal(res.body, "departements"));
  }

  Future<void> loadMatieres() async {
    final res = await http.get(Uri.parse("$baseUrl/matieres"));
    if (!mounted) return;
    setState(() => matieres = hal(res.body, "matieres"));
  }

  Future<void> loadClasses() async {
    final res = await http.get(Uri.parse(
        "$baseUrl/classes/search/findByDepartementCodDept?codDept=$selectedDept"));
    if (!mounted) return;
    setState(() => classes = hal(res.body, "classes"));
  }

  Future<void> loadEtudiants() async {
    final res = await http.get(Uri.parse(
        "$baseUrl/etudiants/search/findByClasseCodClass?codClass=$selectedClasse"));
    if (!mounted) return;
    setState(() => etudiants = hal(res.body, "etudiants"));
  }

  Future<void> loadAbsences() async {
    if (selectedEtudiant == null) return;
    final res = await http.get(Uri.parse("$baseUrl/api/absences/etudiant/$selectedEtudiant"));
    if (!mounted) return;
    setState(() => absences = jsonDecode(res.body));
  }

  // ---------------------------------------------------------------
  // Question 2 : sélections en cascade Département -> Classe -> Etudiant
  // ---------------------------------------------------------------

  void onDeptChanged(dynamic v) {
    setState(() {
      selectedDept = v;
      selectedClasse = null;
      selectedEtudiant = null;
      classes = [];
      etudiants = [];
      absences = [];
      nomCtrl.clear();
      prenomCtrl.clear();
    });
    loadClasses();
  }

  void onClasseChanged(dynamic v) {
    setState(() {
      selectedClasse = v;
      selectedEtudiant = null;
      etudiants = [];
      absences = [];
      nomCtrl.clear();
      prenomCtrl.clear();
    });
    loadEtudiants();
  }

  void onEtudiantChanged(dynamic v) {
    final e = etudiants.firstWhere((x) => x["id"] == v);
    setState(() {
      selectedEtudiant = v;
      nomCtrl.text = e["nom"] ?? "";
      prenomCtrl.text = e["prenom"] ?? "";
    });
    loadAbsences();
  }

  // ---------------------------------------------------------------
  // Question 3 : Ajouter / Mettre à jour / Supprimer
  // ---------------------------------------------------------------

  // id == null -> POST (Ajouter) ; sinon -> PUT (Mettre à jour)
  Future<void> saveAbsence(dynamic id, String codMat, DateTime date, double nha) async {
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({
      "nce": selectedEtudiant,
      "codMat": codMat,
      "dateA": isoDate(date),
      "nha": nha,
    });

    final res = id == null
        ? await http.post(Uri.parse("$baseUrl/api/absences"), headers: headers, body: body)
        : await http.put(Uri.parse("$baseUrl/api/absences/$id"), headers: headers, body: body);

    if (!mounted) return;
    if (res.statusCode == 200) {
      message(id == null ? "Absence ajoutée" : "Absence mise à jour", Colors.green);
      loadAbsences();
    } else if (res.statusCode == 409) {
      message(res.body, Colors.red);
    } else {
      message("Erreur ${res.statusCode}", Colors.red);
    }
  }

  // Supprimer
  Future<void> confirmerSuppression(dynamic a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Supprimer"),
        content: Text("Supprimer l'absence du ${frDate(a["dateA"])} en ${a["codMat"]} ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Non")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Oui")),
        ],
      ),
    );
    if (ok != true) return;

    await http.delete(Uri.parse("$baseUrl/api/absences/${a["id"]}"));
    if (!mounted) return;
    message("Absence supprimée", Colors.green);
    loadAbsences();
  }

  // Formulaire commun : Ajouter (absence == null) ou Mettre à jour
  void ouvrirFormulaire({dynamic absence}) {
    String? codMat = absence?["codMat"] ?? (matieres.isNotEmpty ? matieres[0]["codMat"] : null);
    DateTime date = absence == null ? DateTime.now() : DateTime.parse(absence["dateA"]);
    final nhaCtrl = TextEditingController(text: absence == null ? "" : "${absence["nha"]}");
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(absence == null ? "Ajouter une absence" : "Mettre à jour l'absence"),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Matière
                Row(children: [
                  const Text("Matière : "),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: codMat,
                      items: matieres
                          .map((m) => DropdownMenuItem<String>(
                        value: m["codMat"] as String,
                        child: Text(m["codMat"]),
                      ))
                          .toList(),
                      onChanged: (v) => setDialogState(() => codMat = v),
                    ),
                  ),
                ]),
                // Date
                Row(children: [
                  Text("Date : ${frDate(isoDate(date))}"),
                  IconButton(
                    icon: const Icon(Icons.calendar_month),
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: date,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (d != null) setDialogState(() => date = d);
                    },
                  ),
                ]),
                // NHA
                TextFormField(
                  controller: nhaCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: "NHA (heures)"),
                  validator: (String? v) {
                    final x = double.tryParse((v ?? "").replaceAll(",", "."));
                    if (x == null || x <= 0) return "Nombre d'heures invalide";
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
            ElevatedButton(
              onPressed: () {
                if (!formKey.currentState!.validate() || codMat == null) return;
                final nha = double.parse(nhaCtrl.text.replaceAll(",", "."));
                Navigator.pop(context);
                saveAbsence(absence?["id"], codMat!, date, nha);
              },
              child: const Text("Enregistrer"),
            ),
          ],
        ),
      ),
    );
  }

  // Ouvre l'écran des questions 4 et 5
  void ouvrirTotal() {
    final e = etudiants.firstWhere((x) => x["id"] == selectedEtudiant);
    final c = classes.firstWhere((x) => x["codClass"] == selectedClasse);
    final d = departements.firstWhere((x) => x["codDept"] == selectedDept);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TotalAbsencesPage(
          etudiant: e,
          nomClasse: c["nomClass"] ?? "",
          nomDept: d["nomDept"] ?? "",
        ),
      ),
    );
  }

  // Ouvre l'écran de la question 7 avec l'étudiant déjà choisi
  void ouvrirMoyennes() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MoyennesPage(
          codDept: selectedDept,
          codClass: selectedClasse,
          nce: selectedEtudiant,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------
  // Interface
  // ---------------------------------------------------------------

  Widget liste(String label, dynamic value, List<DropdownMenuItem<dynamic>> items,
      void Function(dynamic) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        SizedBox(
          width: 110,
          child: Text("$label :", style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: DropdownButton<dynamic>(
            isExpanded: true,
            hint: const Text("Choisir"),
            value: value,
            items: items,
            onChanged: onChanged,
          ),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestion des absences"),
        actions: [
          // Ouvre l'écran "Total des absences" (questions 4 et 5)
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: "Total des absences",
            onPressed: selectedEtudiant == null ? null : ouvrirTotal,
          ),
          // Ouvre l'écran "Notes et moyennes" (question 7)
          IconButton(
            icon: const Icon(Icons.grade),
            tooltip: "Notes et moyennes",
            onPressed: selectedEtudiant == null ? null : ouvrirMoyennes,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Liste 1 : tous les départements
            liste(
              "Département",
              selectedDept,
              departements
                  .map((d) => DropdownMenuItem<dynamic>(
                  value: d["codDept"], child: Text(d["nomDept"] ?? "")))
                  .toList(),
              onDeptChanged,
            ),
            // Liste 2 : classes du département sélectionné
            liste(
              "Classe",
              selectedClasse,
              classes
                  .map((c) => DropdownMenuItem<dynamic>(
                  value: c["codClass"], child: Text(c["nomClass"] ?? "")))
                  .toList(),
              onClasseChanged,
            ),
            // Liste 3 : étudiants de la classe sélectionnée
            liste(
              "Etudiant",
              selectedEtudiant,
              etudiants
                  .map((e) => DropdownMenuItem<dynamic>(
                  value: e["id"], child: Text("E${e["id"]} - ${e["nom"]} ${e["prenom"]}")))
                  .toList(),
              onEtudiantChanged,
            ),
            const SizedBox(height: 12),

            // Nom et Prénom dans des zones de texte
            Row(children: [
              Expanded(
                child: TextField(
                  controller: nomCtrl,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: "Nom", border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: prenomCtrl,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: "Prénom", border: OutlineInputBorder()),
                ),
              ),
            ]),
            const SizedBox(height: 16),

            // Tableau des absences : DateA | CodMat | NHA
            if (selectedEtudiant != null)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(Colors.purple.shade50),
                  columns: const [
                    DataColumn(label: Text("DateA")),
                    DataColumn(label: Text("CodMat")),
                    DataColumn(label: Text("NHA"), numeric: true),
                    DataColumn(label: Text("")),
                  ],
                  rows: absences
                      .map((a) => DataRow(cells: [
                    DataCell(Text(frDate(a["dateA"]))),
                    DataCell(Text(a["codMat"])),
                    DataCell(Text("${a["nha"]}")),
                    DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                      // Mettre à jour
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => ouvrirFormulaire(absence: a),
                      ),
                      // Supprimer
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => confirmerSuppression(a),
                      ),
                    ])),
                  ]))
                      .toList(),
                ),
              ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      // Ajouter : bouton + en bas de la fenêtre
      floatingActionButton: selectedEtudiant == null
          ? null
          : FloatingActionButton(
        onPressed: () => ouvrirFormulaire(),
        child: const Icon(Icons.add),
      ),
    );
  }
}