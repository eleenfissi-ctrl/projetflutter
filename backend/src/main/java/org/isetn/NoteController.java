package org.isetn;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@CrossOrigin("*")
@RequestMapping("/api/notes")
public class NoteController {

    // Pondération d'un module de cours : 30 % DS + 70 % Examen
    static final double POIDS_DS = 0.3;
    static final double POIDS_EXAMEN = 0.7;

    @Autowired
    private NoteRepository noteRepository;
    @Autowired
    private EtudiantRepository etudiantRepository;
    @Autowired
    private MatiereRepository matiereRepository;
    @Autowired
    private ClassMatRepository classMatRepository;

    // GET /api/notes/bulletin/1 -> question 7 : notes, moyenne par matière et moyenne générale
    @GetMapping("/bulletin/{nce}")
    public Bulletin bulletin(@PathVariable("nce") Long nce) {
        Etudiant e = etudiantRepository.findById(nce).orElseThrow();

        // Les notes de l'étudiant, rangées par code matière
        Map<String, Note> notes = new LinkedHashMap<>();
        for (Note n : noteRepository.findByEtudiantId(nce)) {
            notes.put(n.getMatiere().getCodMat(), n);
        }

        List<LigneBulletin> lignes = new ArrayList<>();
        double somme = 0, sommeCoef = 0;

        // 1) Toutes les matières de la classe de l'étudiant (table ClassMat)
        List<ClassMat> matieresClasse = e.getClasse() == null ? List.of()
                : classMatRepository.findByClasseCodClass(e.getClasse().getCodClass());
        for (ClassMat cm : matieresClasse) {
            Note n = notes.remove(cm.getMatiere().getCodMat());
            LigneBulletin l = ligne(cm.getMatiere(), cm.getCoef(), n);
            lignes.add(l);
            if (l.moyenne() != null) {
                somme += l.moyenne() * l.coef();
                sommeCoef += l.coef();
            }
        }
        // 2) Les notes dans une matière qui n'est pas affectée à la classe (coef 1)
        for (Note n : notes.values()) {
            LigneBulletin l = ligne(n.getMatiere(), 1.0, n);
            lignes.add(l);
            if (l.moyenne() != null) {
                somme += l.moyenne();
                sommeCoef += 1;
            }
        }

        Double generale = sommeCoef == 0 ? null : arrondi(somme / sommeCoef);
        return new Bulletin(lignes, generale);
    }

    // PUT /api/notes -> Ajouter ou Mettre à jour les notes d'une matière (une ligne par étudiant/matière)
    @PutMapping
    public ResponseEntity<?> enregistrer(@RequestBody NoteRequest req) {
        boolean notesTp = req.tp1() != null || req.tp2() != null;
        boolean notesCours = req.ds() != null || req.examen() != null;
        if (notesTp && notesCours) {
            return ResponseEntity.badRequest()
                    .body("Un module TP a TP1/TP2, un module de cours a DS/Examen : pas les deux");
        }
        for (Double x : new Double[]{req.tp1(), req.tp2(), req.ds(), req.examen()}) {
            if (x != null && (x < 0 || x > 20)) {
                return ResponseEntity.badRequest().body("Une note doit être entre 0 et 20");
            }
        }

        Note n = noteRepository.findByEtudiantIdAndMatiereCodMat(req.nce(), req.codMat())
                .orElseGet(Note::new);
        n.setEtudiant(etudiantRepository.findById(req.nce()).orElseThrow());
        n.setMatiere(matiereRepository.findById(req.codMat()).orElseThrow());
        n.setTp1(req.tp1());
        n.setTp2(req.tp2());
        n.setDs(req.ds());
        n.setExamen(req.examen());
        noteRepository.save(n);
        return ResponseEntity.ok().build();
    }

    // DELETE /api/notes/1/AFCP -> Supprimer les notes d'un étudiant dans une matière
    @DeleteMapping("/{nce}/{codMat}")
    public ResponseEntity<Void> supprimer(@PathVariable("nce") Long nce, @PathVariable("codMat") String codMat) {
        noteRepository.findByEtudiantIdAndMatiereCodMat(nce, codMat).ifPresent(noteRepository::delete);
        return ResponseEntity.status(HttpStatus.NO_CONTENT).build();
    }

    // Construit une ligne du tableau et calcule la moyenne de la matière
    private LigneBulletin ligne(Matiere m, Double coef, Note n) {
        double c = coef == null ? 1.0 : coef;
        if (n == null) {
            return new LigneBulletin(m.getCodMat(), m.getIntMat(), c, null, null, null, null, null, null);
        }
        String type = null;
        Double moyenne = null;
        if (n.getTp1() != null || n.getTp2() != null) {
            // Module TP : moyenne des deux notes de TP
            type = "TP";
            if (n.getTp1() != null && n.getTp2() != null) {
                moyenne = arrondi((n.getTp1() + n.getTp2()) / 2);
            }
        } else if (n.getDs() != null || n.getExamen() != null) {
            // Module de cours : 30 % DS + 70 % Examen
            type = "COURS";
            if (n.getDs() != null && n.getExamen() != null) {
                moyenne = arrondi(n.getDs() * POIDS_DS + n.getExamen() * POIDS_EXAMEN);
            }
        }
        return new LigneBulletin(m.getCodMat(), m.getIntMat(), c, type,
                n.getTp1(), n.getTp2(), n.getDs(), n.getExamen(), moyenne);
    }

    private static double arrondi(double x) {
        return Math.round(x * 100) / 100.0;
    }
}
