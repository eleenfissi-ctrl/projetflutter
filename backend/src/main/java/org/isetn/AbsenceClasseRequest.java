package org.isetn;

import java.time.LocalDate;

// Examen Q1 : saisie du NHA d'un étudiant (matière + date)
// ex : {"nce": 1, "codMat": "AFCP", "dateA": "2026-11-24", "nha": 6}
// nha vide ou 0 -> l'absence est supprimée
public record AbsenceClasseRequest(Long nce, String codMat, LocalDate dateA, Double nha) {
}
