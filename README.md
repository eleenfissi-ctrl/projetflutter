# Projet Flutter + Spring Boot : gestion de scolarité (Suite TP7 + Examen TP DSI32)

## Structure
- `backend/` : API Spring Boot (Java 17, Maven, base H2)
- `frontend/` : application Flutter

## Lancer le backend
```
cd backend
mvn spring-boot:run
```
L'API écoute sur http://localhost:8081 (console H2 : http://localhost:8081/h2-console).
La base est recréée et remplie au démarrage (`ScolA7Application.java`).

## Lancer le frontend
```
cd frontend
flutter pub get
flutter run -d chrome
```
L'adresse de l'API se règle dans `frontend/lib/api.dart`.
Connexion : `admin@gmail.com` / `admin`

## Fonctionnalités
- Gestion des départements, classes (avec matières, coef, CHSM), étudiants, matières, formations, utilisateurs
- Suite TP7 : saisie des absences, total par matière, total du semestre (bouton Calculer), courbe, notes et moyennes
- Examen TP : absences d'une classe dans une matière à une date ; classe la plus nombreuse (comptage dans Etudiant) et mise à jour de NbrEtud
