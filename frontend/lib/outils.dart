import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Petits outils partagés par les écrans de gestion (Suite TP7)

// Décode le JSON en UTF-8 (pour garder les accents : "Prénom", "Département"...)
dynamic lireJson(http.Response res) => jsonDecode(utf8.decode(res.bodyBytes));

// Spring Data REST répond au format HAL : {"_embedded": {"cle": [...]}}
List<dynamic> hal(http.Response res, String cle) {
  return lireJson(res)["_embedded"]?[cle] ?? [];
}

// Texte d'erreur renvoyé par le serveur (ex : 409 doublon)
String erreurServeur(http.Response res) {
  final t = utf8.decode(res.bodyBytes);
  if (res.statusCode == 409) {
    return t.isNotEmpty && !t.startsWith("{") ? t : "Impossible : élément utilisé ailleurs";
  }
  return t.isNotEmpty && !t.startsWith("{") ? t : "Erreur ${res.statusCode}";
}

bool ok(http.Response res) => res.statusCode >= 200 && res.statusCode < 300;

// Lit un nombre saisi ("12,5" ou "12.5") ; null si la zone est vide
double? lireNombre(String texte) {
  final t = texte.trim().replaceAll(",", ".");
  if (t.isEmpty) return null;
  return double.tryParse(t);
}

// Affiche un nombre sans ".0" inutile : 6.0 -> 6 ; 7.5 -> 7.5
String nombre(dynamic x) {
  if (x == null) return "";
  final d = (x as num).toDouble();
  return d == d.roundToDouble() ? d.toInt().toString() : d.toString();
}

void message(BuildContext context, String texte, {bool erreur = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(texte), backgroundColor: erreur ? Colors.red : Colors.green),
  );
}

// Boîte "Oui / Non" avant une suppression
Future<bool> confirmer(BuildContext context, String question) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Supprimer"),
      content: Text(question),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Non")),
        ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Oui")),
      ],
    ),
  );
  return ok == true;
}
