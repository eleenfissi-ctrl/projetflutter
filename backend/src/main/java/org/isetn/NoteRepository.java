package org.isetn;

import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.rest.core.annotation.RepositoryRestResource;

// exported = false : les notes passent uniquement par NoteController (/api/notes)
@RepositoryRestResource(exported = false)
public interface NoteRepository extends JpaRepository<Note, Long> {

    List<Note> findByEtudiantId(Long nce);

    Optional<Note> findByEtudiantIdAndMatiereCodMat(Long nce, String codMat);
}
