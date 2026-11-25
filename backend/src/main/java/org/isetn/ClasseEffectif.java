package org.isetn;

// Examen Q2 : une classe avec son nombre réel d'étudiants (compté dans la table Etudiant)
// et la valeur actuelle de la colonne NbrEtud de la table Classe
public record ClasseEffectif(Long codClass, String nomClass, String nomDept,
                             Long nbEtudiants, Integer nbreEtud) {
}
