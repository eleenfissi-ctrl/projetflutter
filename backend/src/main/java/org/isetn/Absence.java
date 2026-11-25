package org.isetn;

import jakarta.persistence.*;
import java.time.LocalDate;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

// Absence (#CodMat, #NCE, DateA, NHA)
// Un étudiant ne peut pas avoir deux absences dans la même matière à la même date.
@Data
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(uniqueConstraints = @UniqueConstraint(columnNames = {"cod_mat", "nce", "datea"}))
public class Absence {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "cod_mat")
    private Matiere matiere;

    @ManyToOne
    @JoinColumn(name = "nce")
    private Etudiant etudiant;

    @Column(name = "datea")
    private LocalDate dateA;

    private Double nha;    // nombre d'heures d'absence
}