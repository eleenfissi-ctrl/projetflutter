package org.isetn;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.data.rest.core.annotation.RepositoryRestResource;

import java.util.List;

// excerptProjection : chaque classe des listes contient son département
@RepositoryRestResource(excerptProjection = ClasseProjection.class)
public interface ClasseRepository extends JpaRepository<Classe, Long> {

    // Recherche des classes dont le nom contient un mot-clé
    @Query("select c from Classe c where c.nomClass like :x")
    public List<Classe> Chercher(@Param("x") String nom);

    // GET /classes/search/findByDepartementCodDept?codDept=1  (Suite TP7)
    List<Classe> findByDepartementCodDept(@Param("codDept") Long codDept);
}