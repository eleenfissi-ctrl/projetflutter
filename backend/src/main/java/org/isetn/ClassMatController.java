package org.isetn;

import java.util.List;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

// Matières enseignées dans une classe (table ClassMat)
@RestController
@CrossOrigin("*")
@RequestMapping("/api/classmats")
public class ClassMatController {

    @Autowired
    private ClassMatRepository classMatRepository;
    @Autowired
    private ClasseRepository classeRepository;
    @Autowired
    private MatiereRepository matiereRepository;

    // GET /api/classmats/classe/1
    @GetMapping("/classe/{codClass}")
    public List<ClassMatDTO> parClasse(@PathVariable("codClass") Long codClass) {
        return classMatRepository.findByClasseCodClass(codClass).stream().map(ClassMatDTO::from).toList();
    }

    // POST /api/classmats -> affecter une matière à une classe
    @PostMapping
    public ClassMatDTO ajouter(@RequestBody ClassMatRequest req) {
        ClassMat cm = new ClassMat();
        remplir(cm, req);
        return ClassMatDTO.from(classMatRepository.save(cm));
    }

    // PUT /api/classmats/3 -> modifier coef / CHSM
    @PutMapping("/{id}")
    public ClassMatDTO modifier(@PathVariable("id") Long id, @RequestBody ClassMatRequest req) {
        ClassMat cm = classMatRepository.findById(id).orElseThrow();
        remplir(cm, req);
        return ClassMatDTO.from(classMatRepository.save(cm));
    }

    // DELETE /api/classmats/3
    @DeleteMapping("/{id}")
    public void supprimer(@PathVariable("id") Long id) {
        classMatRepository.deleteById(id);
    }

    private void remplir(ClassMat cm, ClassMatRequest req) {
        cm.setClasse(classeRepository.findById(req.codClass()).orElseThrow());
        cm.setMatiere(matiereRepository.findById(req.codMat()).orElseThrow());
        cm.setCoef(req.coef());
        cm.setChsm(req.chsm());
    }

    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<String> doublon() {
        return ResponseEntity.status(HttpStatus.CONFLICT).body("Cette matière est déjà affectée à la classe");
    }
}
