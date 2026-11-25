package org.isetn;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

// Examen TP (DSI32)
@RestController
@CrossOrigin("*")
@RequestMapping("/api/examen")
public class ExamenController {

    @Autowired
    private EtudiantRepository etudiantRepository;
    @Autowired
    private ClasseRepository classeRepository;
    @Autowired
    private MatiereRepository matiereRepository;
    @Autowired
    private ClassMatRepository classMatRepository;
    @Autowired
    private AbsenceRepository absenceRepository;

    // ---------------------------------------------------------------
    // Question 1 : absences d'une classe dans une matière à une date
    // ---------------------------------------------------------------

    // GET /api/examen/absences?codClass=1&codMat=AFCP&date=2026-11-24
    @GetMapping("/absences")
    public AbsencesClasse absencesClasse(@RequestParam("codClass") Long codClass,
                                         @RequestParam("codMat") String codMat,
                                         @RequestParam("date") @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        Classe c = classeRepository.findById(codClass).orElseThrow();
        Matiere m = matiereRepository.findById(codMat).orElseThrow();
        Double chsm = classMatRepository.findByClasseCodClassAndMatiereCodMat(codClass, codMat)
                .map(ClassMat::getChsm).orElse(null);

        // Les absences existantes, rangées par NCE
        Map<Long, Absence> absences = new HashMap<>();
        for (Absence a : absenceRepository.findByEtudiantClasseCodClassAndMatiereCodMatAndDateA(codClass, codMat, date)) {
            absences.put(a.getEtudiant().getId(), a);
        }

        // Tous les étudiants de la classe, avec leur NHA (vide s'ils n'ont pas d'absence)
        List<LigneAbsenceClasse> lignes = new ArrayList<>();
        for (Etudiant e : etudiantRepository.findByClasseCodClass(codClass)) {
            Absence a = absences.get(e.getId());
            lignes.add(new LigneAbsenceClasse(e.getId(), e.getNom(), e.getPrenom(),
                    a == null ? null : a.getId(), a == null ? null : a.getNha()));
        }

        String nomDept = c.getDepartement() == null ? null : c.getDepartement().getNomDept();
        return new AbsencesClasse(c.getCodClass(), c.getNomClass(), nomDept,
                m.getCodMat(), m.getIntMat(), chsm, date, lignes);
    }

    // PUT /api/examen/absences -> ajoute, modifie ou supprime (nha vide ou 0) le NHA d'un étudiant
    @PutMapping("/absences")
    public ResponseEntity<String> saisir(@RequestBody AbsenceClasseRequest req) {
        if (req.nha() != null && req.nha() < 0) {
            return ResponseEntity.badRequest().body("Le NHA ne peut pas être négatif");
        }
        Absence a = absenceRepository
                .findByEtudiantIdAndMatiereCodMatAndDateA(req.nce(), req.codMat(), req.dateA())
                .orElse(null);

        if (req.nha() == null || req.nha() == 0) {
            if (a != null) absenceRepository.delete(a);
            return ResponseEntity.ok().build();
        }
        if (a == null) {
            a = new Absence();
            a.setEtudiant(etudiantRepository.findById(req.nce()).orElseThrow());
            a.setMatiere(matiereRepository.findById(req.codMat()).orElseThrow());
            a.setDateA(req.dateA());
        }
        a.setNha(req.nha());
        absenceRepository.save(a);
        return ResponseEntity.ok().build();
    }





    @GetMapping("/effectifs")
    public List<ClasseEffectif> effectifs() {
        List<ClasseEffectif> resultat = new ArrayList<>();
        for (Object[] ligne : etudiantRepository.compterParClasse()) {
            Long codClass = (Long) ligne[0];
            Long nombre = (Long) ligne[1];
            Classe c = classeRepository.findById(codClass).orElseThrow();
            String nomDept = c.getDepartement() == null ? null : c.getDepartement().getNomDept();
            resultat.add(new ClasseEffectif(c.getCodClass(), c.getNomClass(), nomDept, nombre, c.getNbreEtud()));
        }
        return resultat;
    }

    @GetMapping("/classe-max")
    public List<ClasseEffectif> classeMax() {
        List<ClasseEffectif> tous = effectifs();
        if (tous.isEmpty()) return tous;
        long max = tous.get(0).nbEtudiants();
        return tous.stream().filter(c -> c.nbEtudiants() == max).toList();
    }

    @PutMapping("/classe-max/maj")
    @Transactional
    public List<ClasseEffectif> mettreAJour() {
        for (ClasseEffectif ce : classeMax()) {
            Classe c = classeRepository.findById(ce.codClass()).orElseThrow();
            c.setNbreEtud(ce.nbEtudiants().intValue());
            classeRepository.save(c);
        }
        return classeMax();
    }
}
