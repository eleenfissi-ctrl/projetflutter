package org.isetn;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Entity
public class Matiere {
    // Clé saisie à la main : "AFCP", "SOA"...
    @Id
    private String codMat;

    private String intMat;        // intitulé de la matière

    private String description;
}