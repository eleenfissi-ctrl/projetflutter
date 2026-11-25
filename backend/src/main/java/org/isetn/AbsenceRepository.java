package org.isetn;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.data.rest.core.annotation.RepositoryRestResource;

@RepositoryRestResource(exported = false)
public interface AbsenceRepository extends JpaRepository<Absence, Long> {

    List<Absence> findByEtudiantIdOrderByDateADesc(Long id);

    List<Absence> findByEtudiantClasseCodClassAndMatiereCodMatAndDateA(Long codClass, String codMat,
                                                                      java.time.LocalDate dateA);

    java.util.Optional<Absence> findByEtudiantIdAndMatiereCodMatAndDateA(Long nce, String codMat,
                                                                        java.time.LocalDate dateA);

    @Query("select new org.isetn.TotalAbsence(a.matiere.codMat, sum(a.nha)) " + "from Absence a where a.etudiant.id = :nce " + "group by a.matiere.codMat order by a.matiere.codMat")
    List<TotalAbsence> totalParMatiere(@Param("nce") Long nce);
}