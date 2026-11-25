package org.isetn;

// Examen Q1 : une ligne du tableau "Nom | Prenom | NHA"
// nha = null si l'étudiant n'a pas d'absence ce jour-là dans cette matière
public record LigneAbsenceClasse(Long nce, String nom, String prenom, Long absenceId, Double nha) {
}
