package org.isetn;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

// ClassMat (#CodMat, #CodClass, Coef, CHSM) : les matières enseignées dans chaque classe
@Data
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(uniqueConstraints = @UniqueConstraint(columnNames = {"cod_mat", "cod_class"}))
public class ClassMat {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "cod_mat")
    private Matiere matiere;

    @ManyToOne
    @JoinColumn(name = "cod_class")
    private Classe classe;

    private Double coef;

    private Double chsm;
}