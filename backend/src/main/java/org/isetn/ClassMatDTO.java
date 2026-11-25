package org.isetn;

// Une matière enseignée dans une classe, avec son coefficient et sa charge horaire
public record ClassMatDTO(Long id, Long codClass, String codMat, String intMat, Double coef, Double chsm) {

    public static ClassMatDTO from(ClassMat cm) {
        return new ClassMatDTO(cm.getId(), cm.getClasse().getCodClass(),
                cm.getMatiere().getCodMat(), cm.getMatiere().getIntMat(),
                cm.getCoef(), cm.getChsm());
    }
}
