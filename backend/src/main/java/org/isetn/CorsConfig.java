package org.isetn;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import org.springframework.web.filter.CorsFilter;

// Filtre CORS global : autorise Flutter Web (Chrome) à appeler toutes les URL de l'API
@Configuration
public class CorsConfig {

    @Bean
    public CorsFilter corsFilter() {
        CorsConfiguration config = new CorsConfiguration();
        config.addAllowedOriginPattern("*");   // toutes les origines (localhost:58586...)
        config.addAllowedHeader("*");          // tous les en-têtes (Content-Type...)
        config.addAllowedMethod("*");          // GET, POST, PUT, DELETE, OPTIONS...

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        return new CorsFilter(source);
    }
}