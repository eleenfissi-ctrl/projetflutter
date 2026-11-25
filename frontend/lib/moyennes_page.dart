import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api.dart';
import 'outils.dart';

// Question 7 : notes et moyennes d'un étudiant donné d'une classe donnée
//   Module TP    : Moyenne = (TP1 + TP2) / 2
//   Module cours : Moyenne = 30 % DS + 70 % Examen
//   Moyenne générale = moyennes des matières pondérées par leur coefficient (table ClassMat)
// Le calcul est fait par le backend : GET /api/notes/bulletin/{nce}
//
// On peut ouvrir cet écran depuis le menu (on choisit Département -> Classe -> Etudiant)
// ou depuis l'écran des absences (l'étudiant est déjà choisi).
class MoyennesPage extends StatefulWidget {
  final dynamic codDept;
  final dynamic codClass;
  final dynamic nce;

  const MoyennesPage({super.key, this.codDept, this.codClass, this.nce});

  @override
  State<MoyennesPage> createState() => _MoyennesPageState();
}

class _MoyennesPageState extends State<MoyennesPage> {
  List<dynamic> departements = [];
  List<dynamic> classes = [];
  List<dynamic> etudiants = [];
  dynamic selectedDept;
  dynamic selectedClasse;
  dynamic selectedEtudiant;

  List<dynamic> lignes = [];   // lignes du bulletin
  dynamic moyenneGenerale;
  bool calcule = false;        // le bouton "Calculer" a été cliqué

  @override
  void initState() {
    super.initState();
    demarrer();
  }

  // Charge les listes ; si l'écran est ouvert depuis les absences, présélectionne l'étudiant
  Future<void> demarrer() async {
    await loadDepartements();
    if (widget.codDept == null) return;
    selectedDept = widget.codDept;
    await loadClasses();
    if (widget.codClass == null) return;
    selectedClasse = widget.codClass;
    await loadEtudiants();
    if (widget.nce == null) return;
    setState(() => selectedEtudiant = widget.nce);
    await loadBulletin();
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
    final res = await http.get(Uri.parse(
        "$baseUrl/etudiants/search/findByClasseCodClass?codClass=$selectedClasse"));
    if (!mounted) return;
    setState(() => etudiants = hal(res, "etudiants"));
  }

  Future<void> loadBulletin() async {
    if (selectedEtudiant == null) return;
    final res = await http.get(Uri.parse("$baseUrl/api/notes/bulletin/$selectedEtudiant"));
    if (!mounted) return;
    final data = lireJson(res);
    setState(() {
      lignes = data["lignes"];
      moyenneGenerale = data["moyenneGenerale"];
    });
  }

  // ---------------------------------------------------------------
  // Saisie des notes (Ajouter / Mettre à jour / Supprimer)
  // ---------------------------------------------------------------

  Future<void> enregistrer(String codMat, double? tp1, double? tp2, double? ds, double? examen) async {
    final res = await http.put(
      Uri.parse("$baseUrl/api/notes"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "nce": selectedEtudiant,
        "codMat": codMat,
        "tp1": tp1,
        "tp2": tp2,
        "ds": ds,
        "examen": examen,
      }),
    );
    if (!mounted) return;
    ok(res) ? message(context, "Notes enregistrées") : message(context, erreurServeur(res), erreur: true);
    loadBulletin();
  }

  Future<void> supprimer(dynamic l) async {
    if (!await confirmer(context, "Supprimer les notes de ${l["codMat"]} ?")) return;
    await http.delete(Uri.parse("$baseUrl/api/notes/$selectedEtudiant/${l["codMat"]}"));
    if (!mounted) return;
    message(context, "Notes supprimées");
    loadBulletin();
  }

  void formulaire(dynamic l) {
    // Type du module : déjà connu si des notes existent, sinon on le choisit
    String type = l["type"] ?? "COURS";
    final tp1 = TextEditingController(text: nombre(l["tp1"]));
    final tp2 = TextEditingController(text: nombre(l["tp2"]));
    final ds = TextEditingController(text: nombre(l["ds"]));
    final ex = TextEditingController(text: nombre(l["examen"]));
    final formKey = GlobalKey<FormState>();

    String? valider(String? v) {
      if (v == null || v.trim().isEmpty) return null; // note pas encore connue
      final x = lireNombre(v);
      if (x == null || x < 0 || x > 20) return "Note entre 0 et 20";
      return null;
    }

    Widget champ(TextEditingController c, String label) => TextFormField(
          controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: label),
          validator: valider,
        );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text("Notes de ${l["codMat"]}"),
          content: Form(
            key: formKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: "TP", label: Text("Module TP")),
                  ButtonSegment(value: "COURS", label: Text("Cours")),
                ],
                selected: {type},
                onSelectionChanged: (s) => setDialogState(() => type = s.first),
              ),
              const SizedBox(height: 8),
              if (type == "TP") ...[champ(tp1, "TP1"), champ(tp2, "TP2")],
              if (type == "COURS") ...[champ(ds, "DS"), champ(ex, "Examen")],
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
            ElevatedButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(context);
                // On n'envoie que les notes du type choisi
                type == "TP"
                    ? enregistrer(l["codMat"], lireNombre(tp1.text), lireNombre(tp2.text), null, null)
                    : enregistrer(l["codMat"], null, null, lireNombre(ds.text), lireNombre(ex.text));
              },
              child: const Text("Enregistrer"),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------
  // Interface
  // ---------------------------------------------------------------

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
          style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold, fontSize: 16)),
      TextSpan(text: "$valeur   ", style: const TextStyle(color: Colors.purple, fontSize: 16)),
    ]));
  }

  dynamic trouver(List<dynamic> liste, String cle, dynamic valeur) {
    for (final x in liste) {
      if (x[cle] == valeur) return x;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final d = trouver(departements, "codDept", selectedDept);
    final c = trouver(classes, "codClass", selectedClasse);
    final e = trouver(etudiants, "id", selectedEtudiant);

    return Scaffold(
      appBar: AppBar(title: const Text("Notes et moyennes")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            liste(
              "Département",
              selectedDept,
              departements
                  .map((x) => DropdownMenuItem<dynamic>(
                      value: x["codDept"], child: Text(x["nomDept"] ?? "")))
                  .toList(),
              (v) {
                setState(() {
                  selectedDept = v;
                  selectedClasse = null;
                  selectedEtudiant = null;
                  classes = [];
                  etudiants = [];
                  lignes = [];
                  calcule = false;
                });
                loadClasses();
              },
            ),
            liste(
              "Classe",
              selectedClasse,
              classes
                  .map((x) => DropdownMenuItem<dynamic>(
                      value: x["codClass"], child: Text(x["nomClass"] ?? "")))
                  .toList(),
              (v) {
                setState(() {
                  selectedClasse = v;
                  selectedEtudiant = null;
                  etudiants = [];
                  lignes = [];
                  calcule = false;
                });
                loadEtudiants();
              },
            ),
            liste(
              "Etudiant",
              selectedEtudiant,
              etudiants
                  .map((x) => DropdownMenuItem<dynamic>(
                      value: x["id"], child: Text("E${x["id"]} - ${x["nom"]} ${x["prenom"]}")))
                  .toList(),
              (v) {
                setState(() {
                  selectedEtudiant = v;
                  calcule = false;
                });
                loadBulletin();
              },
            ),
            const Divider(height: 32),

            if (e != null) ...[
              // Classe : DSI33   Département : TI
              Wrap(alignment: WrapAlignment.center, children: [
                info("Classe", c?["nomClass"] ?? ""),
                info("Département", d?["nomDept"] ?? ""),
              ]),
              const SizedBox(height: 6),
              // Etudiant : E1   Nom : Ben Foulen1   Prénom : Foulen1
              Wrap(alignment: WrapAlignment.center, children: [
                info("Etudiant", "E${e["id"]}"),
                info("Nom", "${e["nom"]}"),
                info("Prénom", "${e["prenom"]}"),
              ]),
              const SizedBox(height: 16),

              // Module | TP1 | TP2 | DS | Exam | Moyenne
              Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    border: TableBorder.all(color: Colors.black26),
                    headingRowColor: WidgetStateProperty.all(Colors.purple.shade50),
                    columnSpacing: 20,
                    columns: const [
                      DataColumn(label: Text("Module", style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text("TP1"), numeric: true),
                      DataColumn(label: Text("TP2"), numeric: true),
                      DataColumn(label: Text("DS"), numeric: true),
                      DataColumn(label: Text("Exam"), numeric: true),
                      DataColumn(
                          label: Text("Moyenne", style: TextStyle(fontWeight: FontWeight.bold)),
                          numeric: true),
                      DataColumn(label: Text("")),
                    ],
                    rows: lignes
                        .map((l) => DataRow(cells: [
                              DataCell(Text(l["codMat"] ?? "")),
                              DataCell(Text(nombre(l["tp1"]))),
                              DataCell(Text(nombre(l["tp2"]))),
                              DataCell(Text(nombre(l["ds"]))),
                              DataCell(Text(nombre(l["examen"]))),
                              // La moyenne n'apparaît qu'après "Calculer"
                              DataCell(Text(calcule ? (nombre(l["moyenne"]).isEmpty ? "-" : nombre(l["moyenne"])) : "…",
                                  style: const TextStyle(fontWeight: FontWeight.bold))),
                              DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  tooltip: "Saisir / modifier les notes",
                                  onPressed: () => formulaire(l),
                                ),
                                if (l["type"] != null)
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => supprimer(l),
                                  ),
                              ])),
                            ]))
                        .toList(),
                  ),
                ),
              ),
              if (lignes.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text("Aucune matière pour cette classe : affectez des matières dans « Manage groups ».",
                      textAlign: TextAlign.center),
                ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton.icon(
                  onPressed: lignes.isEmpty ? null : () => setState(() => calcule = true),
                  icon: const Icon(Icons.calculate),
                  label: const Text("Calculer"),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "Moyenne générale : ${calcule ? (moyenneGenerale == null ? "-" : nombre(moyenneGenerale)) : "…"}",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Module TP : (TP1 + TP2) / 2     Cours : 30 % DS + 70 % Examen\n"
                "Moyenne générale pondérée par les coefficients de la classe",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
