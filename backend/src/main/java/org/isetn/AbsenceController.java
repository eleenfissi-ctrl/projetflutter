package org.isetn;

import java.util.List;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@CrossOrigin("*")
@RequestMapping("/api/absences")
public class AbsenceController {

    @Autowired
    private AbsenceRepository absenceRepository;
    @Autowired
    private EtudiantRepository etudiantRepository;
    @Autowired
    private MatiereRepository matiereRepository;

    // GET /api/absences/etudiant/1 -> tableau des absences de l'étudiant 1
    @GetMapping("/etudiant/{nce}")
    public List<AbsenceDTO> parEtudiant(@PathVariable("nce") Long nce) {
        return absenceRepository.findByEtudiantIdOrderByDateADesc(nce)
                .stream().map(AbsenceDTO::from).toList();
    }

    // GET /api/absences/total/1 -> total NHA par matière (question 4)
    @GetMapping("/total/{nce}")
    public List<TotalAbsence> total(@PathVariable("nce") Long nce) {
        return absenceRepository.totalParMatiere(nce);
    }

    // POST /api/absences -> Ajouter
    @PostMapping
    public AbsenceDTO ajouter(@RequestBody AbsenceRequest req) {
        Absence a = new Absence();
        remplir(a, req);
        return AbsenceDTO.from(absenceRepository.save(a));
    }

    // PUT /api/absences/5 -> Mettre à jour
    @PutMapping("/{id}")
    public AbsenceDTO modifier(@PathVariable("id") Long id, @RequestBody AbsenceRequest req) {
        Absence a = absenceRepository.findById(id).orElseThrow();
        remplir(a, req);
        return AbsenceDTO.from(absenceRepository.save(a));
    }

    // DELETE /api/absences/5 -> Supprimer
    @DeleteMapping("/{id}")
    public void supprimer(@PathVariable("id") Long id) {
        absenceRepository.deleteById(id);
    }

    // Copie les données reçues dans l'entité
    private void remplir(Absence a, AbsenceRequest req) {
        a.setEtudiant(etudiantRepository.findById(req.nce()).orElseThrow());
        a.setMatiere(matiereRepository.findById(req.codMat()).orElseThrow());
        a.setDateA(req.dateA());
        a.setNha(req.nha());
    }

    // Même étudiant + même matière + même date -> 409 au lieu d'une erreur 500
    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<String> doublon() {
        return ResponseEntity.status(HttpStatus.CONFLICT)
                .body("Cette absence existe déjà (même matière, même date)");
    }
}