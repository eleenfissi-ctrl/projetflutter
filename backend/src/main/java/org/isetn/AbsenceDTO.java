package org.isetn;

import java.time.LocalDate;

// Ce que l'API renvoie à Flutter pour une absence (JSON simple, sans HAL)
public record AbsenceDTO(Long id, Long nce, String codMat, String intMat, LocalDate dateA, Double nha) {

    // Transforme une entité Absence en DTO
    public static AbsenceDTO from(Absence a) {
        return new AbsenceDTO(
                a.getId(),
                a.getEtudiant().getId(),
                a.getMatiere().getCodMat(),
                a.getMatiere().getIntMat(),
                a.getDateA(),
                a.getNha());
    }
}