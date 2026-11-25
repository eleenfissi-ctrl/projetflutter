import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api.dart';
import 'outils.dart';

// Examen Q2 : la classe qui a le plus grand nombre d'étudiants dans la table Etudiant.
// On compte les lignes de Etudiant (GET /api/examen/classe-max) : on n'utilise PAS NbrEtud.
// Le bouton met à jour la colonne NbrEtud de cette classe avec le nombre compté.
class ClasseMaxPage extends StatefulWidget {
  const ClasseMaxPage({super.key});
  @override
  State<ClasseMaxPage> createState() => _ClasseMaxPageState();
}

class _ClasseMaxPageState extends State<ClasseMaxPage> {
  List<dynamic> classesMax = []; // plusieurs classes seulement en cas d'égalité
  List<dynamic> effectifs = [];  // toutes les classes, pour vérifier le comptage
  bool loading = true;

  @override
  void initState() {
    super.initState();
    charger();
  }

  Future<void> charger() async {
    final rMax = await http.get(Uri.parse("$baseUrl/api/examen/classe-max"));
    final rTous = await http.get(Uri.parse("$baseUrl/api/examen/effectifs"));
    if (!mounted) return;
    setState(() {
      classesMax = lireJson(rMax);
      effectifs = lireJson(rTous);
      loading = false;
    });
  }

  // Bouton : NbrEtud = nombre d'étudiants compté dans la table Etudiant
  Future<void> mettreAJour() async {
    final res = await http.put(Uri.parse("$baseUrl/api/examen/classe-max/maj"));
    if (!mounted) return;
    if (ok(res)) {
      final noms = classesMax.map((c) => c["nomClass"]).join(", ");
      message(context, "NbrEtud de $noms mis à jour");
    } else {
      message(context, erreurServeur(res), erreur: true);
    }
    charger();
  }

  bool aJour(dynamic c) => c["nbreEtud"] == c["nbEtudiants"];

  Widget carte(dynamic c) {
    return Card(
      color: Colors.purple.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          const Icon(Icons.emoji_events, size: 48, color: Colors.orange),
          const SizedBox(height: 8),
          Text("Classe : ${c["nomClass"]}",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text("Département : ${c["nomDept"] ?? "-"}", style: const TextStyle(fontSize: 17)),
          const SizedBox(height: 12),
          Text("Nombre d'étudiants (table Etudiant) : ${c["nbEtudiants"]}",
              style: const TextStyle(fontSize: 18, color: Colors.purple, fontWeight: FontWeight.bold)),
          Text("NbrEtud enregistré (table Classe) : ${c["nbreEtud"]}",
              style: TextStyle(fontSize: 16, color: aJour(c) ? Colors.green : Colors.red)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final aMettreAJour = classesMax.any((c) => !aJour(c));

    return Scaffold(
      appBar: AppBar(title: const Text("Classe la plus nombreuse")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: charger,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (classesMax.isEmpty)
                    const Center(child: Text("Aucun étudiant dans la table Etudiant")),
                  if (classesMax.length > 1)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text("Égalité : plusieurs classes ont le même nombre d'étudiants",
                          textAlign: TextAlign.center),
                    ),
                  ...classesMax.map(carte),
                  const SizedBox(height: 16),

                  // Bouton de mise à jour de NbrEtud
                  if (classesMax.isNotEmpty)
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: aMettreAJour ? mettreAJour : null,
                        icon: const Icon(Icons.sync),
                        label: Text(aMettreAJour
                            ? "Mettre à jour NbrEtud"
                            : "NbrEtud est déjà à jour"),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Détail du comptage pour toutes les classes
                  const Text("Comptage par classe",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      border: TableBorder.all(color: Colors.black26),
                      columns: const [
                        DataColumn(label: Text("Classe")),
                        DataColumn(label: Text("Département")),
                        DataColumn(label: Text("Étudiants comptés"), numeric: true),
                        DataColumn(label: Text("NbrEtud"), numeric: true),
                      ],
                      rows: effectifs
                          .map((c) => DataRow(cells: [
                                DataCell(Text(c["nomClass"] ?? "")),
                                DataCell(Text(c["nomDept"] ?? "-")),
                                DataCell(Text("${c["nbEtudiants"]}")),
                                DataCell(Text("${c["nbreEtud"]}")),
                              ]))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
