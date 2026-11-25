package org.isetn;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

// Note (#NCE, #CodMat, TP1, TP2, DS, Examen) : une seule ligne par étudiant et par matière
// Module TP    -> TP1 et TP2 remplis (DS et Examen vides)
// Module cours -> DS et Examen remplis (TP1 et TP2 vides)
@Data
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(uniqueConstraints = @UniqueConstraint(columnNames = {"nce", "cod_mat"}))
public class Note {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "nce")
    private Etudiant etudiant;

    @ManyToOne
    @JoinColumn(name = "cod_mat")
    private Matiere matiere;

    private Double tp1;
    private Double tp2;
    private Double ds;
    private Double examen;
}
