package org.isetn;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface FormationRepository extends JpaRepository<Formation, Long> {

    // Recherche des formations dont le nom contient un mot-clé
    @Query("select f from Formation f where f.nom like :x")
    List<Formation> Chercher(@Param("x") String mc);
}