package org.isetn;

// Une ligne du tableau "Module | TP1 | TP2 | DS | Exam | Moyenne" (question 7)
// type = "TP", "COURS" ou null (aucune note saisie)
public record LigneBulletin(String codMat, String intMat, Double coef, String type,
                            Double tp1, Double tp2, Double ds, Double examen, Double moyenne) {
}
