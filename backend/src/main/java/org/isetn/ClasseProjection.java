package org.isetn;

import org.springframework.data.rest.core.config.Projection;

// Projection utilisée dans les listes de classes : ajoute le département dans le JSON
// (sinon Spring Data REST ne donne qu'un lien vers le département)
@Projection(name = "avecDepartement", types = { Classe.class })
public interface ClasseProjection {
	Long getCodClass();
	String getNomClass();
	int getNbreEtud();
	Departement getDepartement();
}
