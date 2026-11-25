import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api.dart';
import 'outils.dart';

class TotalAbsencesPage extends StatefulWidget {
  final dynamic etudiant;
  final String nomClasse;
  final String nomDept;

  const TotalAbsencesPage({
    super.key,
    required this.etudiant,
    required this.nomClasse,
    required this.nomDept,
  });

  @override
  State<TotalAbsencesPage> createState() => _TotalAbsencesPageState();
}

class _TotalAbsencesPageState extends State<TotalAbsencesPage> {
  List<dynamic> totaux = []; // [{"codMat": "AFCP", "totalNha": 6.0}, ...]
  bool loading = true;
  double? totalSemestre; // question 5 : rempli quand on clique sur "Calculer"

  @override
  void initState() {
    super.initState();
    loadTotaux();
  }

  Future<void> loadTotaux() async {
    final res = await http.get(Uri.parse("$baseUrl/api/absences/total/${widget.etudiant["id"]}"));
    if (!mounted) return;
    setState(() {
      totaux = lireJson(res);
      loading = false;
    });
  }

  double val(dynamic x) => (x as num).toDouble();

  // Question 5 : total des absences de l'étudiant, toutes matières confondues
  void calculer() {
    setState(() {
      totalSemestre = totaux.fold<double>(0, (somme, t) => somme + val(t["totalNha"]));
    });
  }

  Widget info(String label, String valeur) {
    return Text.rich(TextSpan(children: [
      TextSpan(
          text: "$label : ",
          style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold, fontSize: 16)),
      TextSpan(text: "$valeur   ", style: const TextStyle(color: Colors.purple, fontSize: 16)),
    ]));
  }

  // Question 6 : courbe déduite du tableau (mêmes données "totaux")
  Widget courbe() {
    final spots = <FlSpot>[
      for (int i = 0; i < totaux.length; i++) FlSpot(i.toDouble(), val(totaux[i]["totalNha"])),
    ];
    final maxY = totaux.map((t) => val(t["totalNha"])).reduce((a, b) => a > b ? a : b);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: totaux.length > 1 ? (totaux.length - 1).toDouble() : 1,
        minY: 0,
        maxY: maxY + 2,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            preventCurveOverShooting: true,
            barWidth: 3,
            color: Colors.purple,
            dotData: const FlDotData(show: true),
          ),
        ],
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (value != i.toDouble() || i < 0 || i >= totaux.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(totaux[i]["codMat"]),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.etudiant;

    return Scaffold(
      appBar: AppBar(title: const Text("Total des absences")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ===== Question 4 =====
            // Classe : DSI33   Département : TI
            Wrap(alignment: WrapAlignment.center, children: [
              info("Classe", widget.nomClasse),
              info("Département", widget.nomDept),
            ]),
            const SizedBox(height: 6),
            // Etudiant : E1   Nom : Ben Foulen1   Prénom : Foulen1
            Wrap(alignment: WrapAlignment.center, children: [
              info("Etudiant", "E${e["id"]}"),
              info("Nom", "${e["nom"]}"),
              info("Prénom", "${e["prenom"]}"),
            ]),
            const SizedBox(height: 16),
            // Tableau CodMat | Total NHA
            DataTable(
              border: TableBorder.all(color: Colors.black26),
              columns: const [
                DataColumn(label: Text("CodMat", style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text("Total NHA", style: TextStyle(fontWeight: FontWeight.bold)),
                    numeric: true),
              ],
              rows: totaux
                  .map((t) => DataRow(cells: [
                DataCell(Text(t["codMat"])),
                DataCell(Text(nombre(t["totalNha"]))),
              ]))
                  .toList(),
            ),
            const SizedBox(height: 16),

            // ===== Question 5 : bouton Calculer =====
            ElevatedButton.icon(
              onPressed: totaux.isEmpty ? null : calculer,
              icon: const Icon(Icons.calculate),
              label: const Text("Calculer"),
            ),
            const SizedBox(height: 12),
            if (totalSemestre != null)
              Text(
                "Total des absences / semestre : ${nombre(totalSemestre)}",
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple),
              ),
            if (totaux.isEmpty) const Text("Aucune absence pour cet étudiant"),
            const SizedBox(height: 24),

            // ===== Question 6 : courbe =====
            const Text("Courbe des absences par matière",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (totaux.isNotEmpty)
              SizedBox(
                height: 260,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: courbe(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}