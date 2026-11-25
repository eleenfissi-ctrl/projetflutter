package org.isetn;

import java.time.LocalDate;
import java.util.List;

// Examen Q1 : en-tête (Classe, Département, Matière, CHSM, Date) + tableau des étudiants
public record AbsencesClasse(Long codClass, String nomClass, String nomDept,
                             String codMat, String intMat, Double chsm, LocalDate date,
                             List<LigneAbsenceClasse> lignes) {
}
