package org.isetn;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.rest.core.annotation.RepositoryRestResource;

// exported = false : ClassMat passe par ClassMatController (/api/classmats)
@RepositoryRestResource(exported = false)
public interface ClassMatRepository extends JpaRepository<ClassMat, Long> {

    List<ClassMat> findByClasseCodClass(Long codClass);

    java.util.Optional<ClassMat> findByClasseCodClassAndMatiereCodMat(Long codClass, String codMat);
}
