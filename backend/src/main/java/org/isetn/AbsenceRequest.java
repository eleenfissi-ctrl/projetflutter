package org.isetn;

import java.time.LocalDate;

// Ce que Flutter envoie pour ajouter / modifier une absence
// ex : {"nce": 1, "codMat": "AFCP", "dateA": "2025-11-11", "nha": 1.5}
public record AbsenceRequest(Long nce, String codMat, LocalDate dateA, Double nha) {
}