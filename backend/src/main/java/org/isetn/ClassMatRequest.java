package org.isetn;

// ex : {"codClass": 1, "codMat": "AFCP", "coef": 2, "chsm": 45}
public record ClassMatRequest(Long codClass, String codMat, Double coef, Double chsm) {
}
