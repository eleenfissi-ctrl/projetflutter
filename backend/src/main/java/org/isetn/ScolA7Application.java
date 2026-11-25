package org.isetn;

import java.time.LocalDate;
import java.util.Date;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class ScolA7Application implements CommandLineRunner {
	@Autowired
	private FormationRepository formationRepository;
	@Autowired
	private ClasseRepository classeRepository;
	@Autowired
	private EtudiantRepository etudiantRepository;
	@Autowired
	private UserRepository userRepository;
	// NOUVEAU
	@Autowired
	private DepartementRepository departementRepository;
	@Autowired
	private MatiereRepository matiereRepository;
	@Autowired
	private ClassMatRepository classMatRepository;
	@Autowired
	private AbsenceRepository absenceRepository;
	@Autowired
	private NoteRepository noteRepository;

	public static void main(String[] args) {
		SpringApplication.run(ScolA7Application.class, args);
	}

	@Override
	public void run(String... args) throws Exception {
		User u1 = userRepository.save(new User(null, "admin@gmail.com", "admin"));

		// Formations : (id, nom, duree, etudiants)
		Formation f1 = formationRepository.save(new Formation(null, "Oracle", 100, null));
		Formation f2 = formationRepository.save(new Formation(null, "J2EE", 10, null));
		Formation f3 = formationRepository.save(new Formation(null, "Angular", 120, null));

		// NOUVEAU - Départements : (codDept, nomDept)
		Departement ti = departementRepository.save(new Departement(null, "TI"));
		Departement ge = departementRepository.save(new Departement(null, "GE"));

		// Classes : (codClass, nomClass, nbreEtud, etudiants, departement)
		Classe c4 = classeRepository.save(new Classe(null, "DSI33", 22, null, ti));
		Classe c1 = classeRepository.save(new Classe(null, "DSI23", 27, null, ti));
		Classe c2 = classeRepository.save(new Classe(null, "DSI22", 25, null, ti));
		Classe c3 = classeRepository.save(new Classe(null, "DSI21", 20, null, ti));
		Classe c5 = classeRepository.save(new Classe(null, "EI21", 18, null, ge));

		// Etudiants : (id=NCE, nom, prenom, dateNais, formation, classe, lieuNais)
		// E1 en premier pour qu'il ait l'id 1, comme dans l'énoncé
		Etudiant e1 = etudiantRepository.save(new Etudiant(null, "Ben Foulen1", "Foulen1", new Date(), f2, "Nabeul", c4));
		Etudiant e2 = etudiantRepository.save(new Etudiant(null, "Ben Foulen2", "Foulen2", new Date(), f2, "Tunis", c4));
		etudiantRepository.save(new Etudiant(null, "Ali", "Ben Ali", new Date(), f1, "Sousse", c1));
		etudiantRepository.save(new Etudiant(null, "Mohamed", "Ben Mohamed", new Date(), f1, "Nabeul", c1));
		etudiantRepository.save(new Etudiant(null, "Amin", "Ben Mahmoud", new Date(), f2, "Hammamet", c1));
		etudiantRepository.save(new Etudiant(null, "Samia", "Ben Ahmed", new Date(), f3, "Tunis", c1));
		etudiantRepository.save(new Etudiant(null, "Foulen", "Ben Foulen3", new Date(), f3, "Nabeul", c2));
		etudiantRepository.save(new Etudiant(null, "Foulen", "Ben Foulen4", new Date(), f3, "Bizerte", c3));
		etudiantRepository.save(new Etudiant(null, "Salah", "Ben Salah", new Date(), f1, "Sfax", c5));
		// NOUVEAU - Matières : (codMat, intMat, description)
		Matiere afcp = matiereRepository.save(new Matiere("AFCP", "Atelier Framework Cross-Platform", "Flutter"));
		Matiere soa = matiereRepository.save(new Matiere("SOA", "Architecture orientée services", "Spring Boot"));
		Matiere bd = matiereRepository.save(new Matiere("BD", "Bases de données", "SQL"));

		// NOUVEAU - ClassMat : (id, matiere, classe, coef, chsm)
		classMatRepository.save(new ClassMat(null, afcp, c4, 2.0, 45.0));
		classMatRepository.save(new ClassMat(null, soa, c4, 2.0, 45.0));
		classMatRepository.save(new ClassMat(null, bd, c4, 1.5, 30.0));

		// NOUVEAU - Absences de E1 (exemple de l'énoncé) : (id, matiere, etudiant, dateA, nha)
		absenceRepository.save(new Absence(null, afcp, e1, LocalDate.of(2025, 11, 11), 1.5));
		absenceRepository.save(new Absence(null, afcp, e1, LocalDate.of(2025, 10, 4), 4.5));
		absenceRepository.save(new Absence(null, soa, e1, LocalDate.of(2025, 10, 20), 1.5));
		absenceRepository.save(new Absence(null, soa, e1, LocalDate.of(2025, 10, 23), 3.0));
		absenceRepository.save(new Absence(null, soa, e1, LocalDate.of(2025, 10, 16), 3.0));
		absenceRepository.save(new Absence(null, bd, e2, LocalDate.of(2025, 10, 30), 3.0));

		// Examen Q1 - absences de la classe DSI33 en AFCP le 24-11-2026 (exemple de l'énoncé)
		absenceRepository.save(new Absence(null, afcp, e1, LocalDate.of(2026, 11, 24), 6.0));
		absenceRepository.save(new Absence(null, afcp, e2, LocalDate.of(2026, 11, 24), 3.0));

		// Suite TP7 Q7 - Notes : (id, etudiant, matiere, tp1, tp2, ds, examen)
		// AFCP est un module TP (TP1, TP2) ; SOA et BD sont des modules de cours (DS, Examen)
		noteRepository.save(new Note(null, e1, afcp, 15.0, 14.0, null, null));
		noteRepository.save(new Note(null, e1, soa, null, null, 12.0, 13.5));
		noteRepository.save(new Note(null, e1, bd, null, null, 10.0, 11.0));
		noteRepository.save(new Note(null, e2, afcp, 12.0, 16.0, null, null));
		noteRepository.save(new Note(null, e2, soa, null, null, 9.5, 11.0));
	}
}