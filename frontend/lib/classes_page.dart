import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api.dart';
import 'outils.dart';

// Gestion des classes : Classe (CodClass, NomClass, NbrEtud, #CodDept)
// + les matières enseignées dans chaque classe : ClassMat (#CodMat, #CodClass, Coef, CHSM)
class ClassesPage extends StatefulWidget {
  const ClassesPage({super.key});
  @override
  State<ClassesPage> createState() => _ClassesPageState();
}

class _ClassesPageState extends State<ClassesPage> {
  List<dynamic> classes = [];
  List<dynamic> departements = [];
  dynamic filtreDept; // null = tous les départements
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadDepartements();
    loadClasses();
  }

  Future<void> loadDepartements() async {
    final res = await http.get(Uri.parse("$baseUrl/departements"));
    if (!mounted) return;
    setState(() => departements = hal(res, "departements"));
  }

  // Chaque classe contient son département grâce à la projection "avecDepartement"
  Future<void> loadClasses() async {
    final url = filtreDept == null
        ? "$baseUrl/classes"
        : "$baseUrl/classes/search/findByDepartementCodDept?codDept=$filtreDept";
    final res = await http.get(Uri.parse(url));
    if (!mounted) return;
    setState(() {
      classes = hal(res, "classes");
      loading = false;
    });
  }

  // id == null -> POST (Ajouter) ; sinon -> PATCH (Mettre à jour)
  // Le lien vers le département s'envoie sous forme d'URL : ".../departements/1"
  Future<void> enregistrer(dynamic id, String nom, int nbre, dynamic codDept) async {
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({
      "nomClass": nom,
      "nbreEtud": nbre,
      "departement": "$baseUrl/departements/$codDept",
    });
    final res = id == null
        ? await http.post(Uri.parse("$baseUrl/classes"), headers: headers, body: body)
        : await http.patch(Uri.parse("$baseUrl/classes/$id"), headers: headers, body: body);
    if (!mounted) return;
    ok(res)
        ? message(context, id == null ? "Classe ajoutée" : "Classe mise à jour")
        : message(context, erreurServeur(res), erreur: true);
    loadClasses();
  }

  Future<void> supprimer(dynamic c) async {
    if (!await confirmer(context, "Supprimer la classe ${c["nomClass"]} ?")) return;
    final res = await http.delete(Uri.parse("$baseUrl/classes/${c["codClass"]}"));
    if (!mounted) return;
    ok(res)
        ? message(context, "Classe supprimée")
        : message(context, "Impossible : cette classe contient des étudiants ou des matières",
            erreur: true);
    loadClasses();
  }

  void formulaire({dynamic classe}) {
    final nomCtrl = TextEditingController(text: classe?["nomClass"] ?? "");
    final nbreCtrl = TextEditingController(text: classe == null ? "" : "${classe["nbreEtud"]}");
    dynamic codDept = classe?["departement"]?["codDept"] ??
        filtreDept ??
        (departements.isNotEmpty ? departements[0]["codDept"] : null);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(classe == null ? "Nouvelle classe" : "Modifier la classe"),
          content: Form(
            key: formKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(
                controller: nomCtrl,
                decoration: const InputDecoration(labelText: "Nom (ex : DSI31)"),
                validator: (v) => (v == null || v.trim().isEmpty) ? "Nom obligatoire" : null,
              ),
              TextFormField(
                controller: nbreCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Nombre d'étudiants"),
                validator: (v) => int.tryParse(v ?? "") == null ? "Nombre invalide" : null,
              ),
              const SizedBox(height: 8),
              Row(children: [
                const Text("Département : "),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<dynamic>(
                    isExpanded: true,
                    value: codDept,
                    hint: const Text("Choisir"),
                    items: departements
                        .map((d) => DropdownMenuItem<dynamic>(
                            value: d["codDept"], child: Text(d["nomDept"] ?? "")))
                        .toList(),
                    onChanged: (v) => setDialogState(() => codDept = v),
                  ),
                ),
              ]),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
            ElevatedButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                if (codDept == null) {
                  message(context, "Choisissez un département", erreur: true);
                  return;
                }
                Navigator.pop(context);
                enregistrer(classe?["codClass"], nomCtrl.text.trim(), int.parse(nbreCtrl.text),
                    codDept);
              },
              child: const Text("Enregistrer"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage groups")),
      body: Column(children: [
        // Filtre par département
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            const Text("Département : ", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            DropdownButton<dynamic>(
              value: filtreDept,
              items: [
                const DropdownMenuItem<dynamic>(value: null, child: Text("Tous")),
                ...departements.map((d) => DropdownMenuItem<dynamic>(
                    value: d["codDept"], child: Text(d["nomDept"] ?? ""))),
              ],
              onChanged: (v) {
                setState(() => filtreDept = v);
                loadClasses();
              },
            ),
          ]),
        ),
        const Divider(height: 1),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: classes.length,
                  itemBuilder: (context, i) {
                    final c = classes[i];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(child: Text("${c["nbreEtud"]}")),
                        title: Text(c["nomClass"] ?? ""),
                        subtitle: Text(
                            "Code : ${c["codClass"]}   Département : ${c["departement"]?["nomDept"] ?? "-"}"),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          // Matières de la classe (ClassMat)
                          IconButton(
                            icon: const Icon(Icons.menu_book, color: Colors.deepOrange),
                            tooltip: "Matières de la classe",
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ClassMatPage(classe: c)),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => formulaire(classe: c),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => supprimer(c),
                          ),
                        ]),
                      ),
                    );
                  },
                ),
        ),
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: () => formulaire(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ---------------------------------------------------------------
// Matières d'une classe : ClassMat (#CodMat, #CodClass, Coef, CHSM)
// ---------------------------------------------------------------
class ClassMatPage extends StatefulWidget {
  final dynamic classe;
  const ClassMatPage({super.key, required this.classe});
  @override
  State<ClassMatPage> createState() => _ClassMatPageState();
}

class _ClassMatPageState extends State<ClassMatPage> {
  List<dynamic> classMats = [];
  List<dynamic> matieres = [];

  dynamic get codClass => widget.classe["codClass"];

  @override
  void initState() {
    super.initState();
    loadClassMats();
    loadMatieres();
  }

  Future<void> loadClassMats() async {
    final res = await http.get(Uri.parse("$baseUrl/api/classmats/classe/$codClass"));
    if (!mounted) return;
    setState(() => classMats = lireJson(res));
  }

  Future<void> loadMatieres() async {
    final res = await http.get(Uri.parse("$baseUrl/matieres"));
    if (!mounted) return;
    setState(() => matieres = hal(res, "matieres"));
  }

  Future<void> enregistrer(dynamic id, String codMat, double coef, double chsm) async {
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({"codClass": codClass, "codMat": codMat, "coef": coef, "chsm": chsm});
    final res = id == null
        ? await http.post(Uri.parse("$baseUrl/api/classmats"), headers: headers, body: body)
        : await http.put(Uri.parse("$baseUrl/api/classmats/$id"), headers: headers, body: body);
    if (!mounted) return;
    ok(res)
        ? message(context, id == null ? "Matière affectée" : "Matière mise à jour")
        : message(context, erreurServeur(res), erreur: true);
    loadClassMats();
  }

  Future<void> supprimer(dynamic cm) async {
    if (!await confirmer(context, "Retirer ${cm["codMat"]} de la classe ?")) return;
    await http.delete(Uri.parse("$baseUrl/api/classmats/${cm["id"]}"));
    if (!mounted) return;
    message(context, "Matière retirée");
    loadClassMats();
  }

  void formulaire({dynamic cm}) {
    String? codMat = cm?["codMat"] ?? (matieres.isNotEmpty ? matieres[0]["codMat"] : null);
    final coefCtrl = TextEditingController(text: cm == null ? "1" : nombre(cm["coef"]));
    final chsmCtrl = TextEditingController(text: cm == null ? "" : nombre(cm["chsm"]));
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(cm == null ? "Affecter une matière" : "Modifier ${cm["codMat"]}"),
          content: Form(
            key: formKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                const Text("Matière : "),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: codMat,
                    items: matieres
                        .map((m) => DropdownMenuItem<String>(
                            value: m["codMat"] as String, child: Text(m["codMat"])))
                        .toList(),
                    onChanged: cm == null ? (v) => setDialogState(() => codMat = v) : null,
                  ),
                ),
              ]),
              TextFormField(
                controller: coefCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: "Coefficient"),
                validator: (v) => (lireNombre(v ?? "") ?? 0) <= 0 ? "Coefficient invalide" : null,
              ),
              TextFormField(
                controller: chsmCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: "CHSM (heures / semestre)"),
                validator: (v) => (lireNombre(v ?? "") ?? 0) <= 0 ? "Charge horaire invalide" : null,
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
            ElevatedButton(
              onPressed: () {
                if (!formKey.currentState!.validate() || codMat == null) return;
                Navigator.pop(context);
                enregistrer(cm?["id"], codMat!, lireNombre(coefCtrl.text)!,
                    lireNombre(chsmCtrl.text)!);
              },
              child: const Text("Enregistrer"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Matières de ${widget.classe["nomClass"]}")),
      body: classMats.isEmpty
          ? const Center(child: Text("Aucune matière affectée à cette classe"))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(Colors.purple.shade50),
                columns: const [
                  DataColumn(label: Text("CodMat")),
                  DataColumn(label: Text("Intitulé")),
                  DataColumn(label: Text("Coef"), numeric: true),
                  DataColumn(label: Text("CHSM"), numeric: true),
                  DataColumn(label: Text("")),
                ],
                rows: classMats
                    .map((cm) => DataRow(cells: [
                          DataCell(Text(cm["codMat"] ?? "")),
                          DataCell(Text(cm["intMat"] ?? "")),
                          DataCell(Text(nombre(cm["coef"]))),
                          DataCell(Text(nombre(cm["chsm"]))),
                          DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => formulaire(cm: cm),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => supprimer(cm),
                            ),
                          ])),
                        ]))
                    .toList(),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => formulaire(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
