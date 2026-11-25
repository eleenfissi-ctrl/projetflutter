package org.isetn;

import java.util.List;

// Réponse complète de la question 7 : les lignes + la moyenne générale
public record Bulletin(List<LigneBulletin> lignes, Double moyenneGenerale) {
}
