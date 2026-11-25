package org.isetn;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import jakarta.persistence.*;
import java.util.Collection;

@Entity
@Data
@AllArgsConstructor
@NoArgsConstructor
public class Classe {
	@Id @GeneratedValue(strategy=GenerationType.IDENTITY)
	private Long codClass;
	private String nomClass;
	private int nbreEtud;
	@OneToMany(mappedBy="classe")
	private Collection<Etudiant> etudiants;

	// NOUVEAU : une classe appartient à un département (#CodDept)
	@ManyToOne
	@JoinColumn(name = "cod_dept")
	private Departement departement;

}