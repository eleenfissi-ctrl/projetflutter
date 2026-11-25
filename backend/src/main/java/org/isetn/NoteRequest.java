package org.isetn;

// Ce que Flutter envoie pour enregistrer les notes d'un étudiant dans une matière
// ex TP    : {"nce": 1, "codMat": "AFCP", "tp1": 15, "tp2": 14}
// ex cours : {"nce": 1, "codMat": "SOA", "ds": 12, "examen": 13}
public record NoteRequest(Long nce, String codMat, Double tp1, Double tp2, Double ds, Double examen) {
}
