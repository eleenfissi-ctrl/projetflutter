import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'classes_page.dart';
import 'etudiants_page.dart';
import 'formations_page.dart';
import 'absences_page.dart';   // NOUVEAU
import 'departements_page.dart';
import 'matieres_page.dart';
import 'moyennes_page.dart';
import 'users_page.dart';
import 'absences_classe_page.dart';
import 'classe_max_page.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  // Ferme le drawer puis ouvre la page demandée
  void ouvrir(BuildContext context, Widget page) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(232, 165, 220, 1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D3B66),
        foregroundColor: Colors.white,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: Colors.purple),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text("ISET", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
              ),
              accountName: Text("Exercise for groups :"),
              accountEmail: Text("DSI33 and DSI31"),
            ),
            ListTile(
              leading: const Icon(Icons.apartment, color: Colors.deepOrange),
              title: const Text("Manage departments"),
              onTap: () => ouvrir(context, const DepartementsPage()),
            ),
            ListTile(
              leading: const Icon(Icons.group, color: Colors.deepOrange),
              title: const Text("Manage groups"),
              onTap: () => ouvrir(context, const ClassesPage()),
            ),
            ListTile(
              leading: const Icon(Icons.school, color: Colors.deepOrange),
              title: const Text("Manage students"),
              onTap: () => ouvrir(context, const EtudiantsPage()),
            ),
            ListTile(
              leading: const Icon(Icons.menu_book, color: Colors.deepOrange),
              title: const Text("Manage trainings"),
              onTap: () => ouvrir(context, const FormationsPage()),
            ),
            ListTile(
              leading: const Icon(Icons.library_books, color: Colors.deepOrange),
              title: const Text("Manage subjects"),
              onTap: () => ouvrir(context, const MatieresPage()),
            ),
            ListTile(
              leading: const Icon(Icons.manage_accounts, color: Colors.deepOrange),
              title: const Text("Manage users"),
              onTap: () => ouvrir(context, const UsersPage()),
            ),
            // NOUVEAU : Suite TP7 - gestion des absences
            ListTile(
              leading: const Icon(Icons.event_busy, color: Colors.deepOrange),
              title: const Text("Gestion des absences"),
              onTap: () => ouvrir(context, const AbsencesPage()),
            ),
            // Suite TP7 Q7 - notes et moyennes
            ListTile(
              leading: const Icon(Icons.grade, color: Colors.deepOrange),
              title: const Text("Notes et moyennes"),
              onTap: () => ouvrir(context, const MoyennesPage()),
            ),
            // Examen TP (DSI32)
            ListTile(
              leading: const Icon(Icons.fact_check, color: Colors.deepOrange),
              title: const Text("Absences d'une classe"),
              onTap: () => ouvrir(context, const AbsencesClassePage()),
            ),
            ListTile(
              leading: const Icon(Icons.emoji_events, color: Colors.deepOrange),
              title: const Text("Classe la plus nombreuse"),
              onTap: () => ouvrir(context, const ClasseMaxPage()),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.deepOrange),
              title: const Text("Close"),
              onTap: () => Navigator.pop(context),   // ferme seulement le drawer
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Align(
          alignment: Alignment.topCenter,
          child: Text("Dashboard",
              style: GoogleFonts.pacifico(fontSize: 40, color: Colors.white)),
        ),
      ),
    );
  }
}