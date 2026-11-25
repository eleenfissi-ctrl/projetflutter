package org.isetn;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.data.rest.core.annotation.RestResource;

public interface EtudiantRepository extends JpaRepository<Etudiant, Long> {

	// Recherche des étudiants dont le nom contient un mot-clé
	@Query("select e from Etudiant e where e.nom like :x")
	List<Etudiant> Chercher(@Param("x") String mc);

	List<Etudiant> findByClasseCodClass(@Param("codClass") Long codClass);

	@RestResource(exported = false)
	@Query("select e.classe.codClass, count(e) from Etudiant e where e.classe is not null " + "group by e.classe.codClass order by count(e) desc")
	List<Object[]> compterParClasse();
}