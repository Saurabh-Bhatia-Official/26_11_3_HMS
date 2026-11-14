package com.caresync.backend.security;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.security.web.header.writers.StaticHeadersWriter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.beans.factory.annotation.Qualifier;

import java.net.URI;
import java.util.Arrays;
import java.util.List;

@Configuration
@EnableScheduling
public class SecurityConfiguration {
    @Bean
    CorsConfigurationSource corsConfigurationSource(
            @Value("${caresync.security.cors.allowed-origins:}") String configuredOrigins) {
        List<String> origins = Arrays.stream(configuredOrigins.split(","))
                .map(String::trim).filter(origin -> !origin.isEmpty()).toList();
        for (String origin : origins) {
            try {
                URI uri = URI.create(origin);
                if ("*".equals(origin) || !("https".equalsIgnoreCase(uri.getScheme())
                        || "http".equalsIgnoreCase(uri.getScheme())) || uri.getHost() == null
                        || (uri.getRawPath() != null && !uri.getRawPath().isEmpty() && !"/".equals(uri.getRawPath()))
                        || uri.getRawQuery() != null || uri.getRawFragment() != null) {
                    throw new IllegalStateException("CARESYNC_CORS_ALLOWED_ORIGINS must contain exact HTTP(S) origins");
                }
            } catch (IllegalArgumentException invalidOrigin) {
                throw new IllegalStateException("CARESYNC_CORS_ALLOWED_ORIGINS contains an invalid origin", invalidOrigin);
            }
        }
        CorsConfiguration cors = new CorsConfiguration();
        cors.setAllowedOrigins(origins);
        cors.setAllowedMethods(List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
        cors.setAllowedHeaders(List.of("Authorization", "Content-Type"));
        cors.setAllowCredentials(false);
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", cors);
        return source;
    }

    @Bean
    PasswordEncoder passwordEncoder() { return new BCryptPasswordEncoder(12); }

    @Bean
    JwtDecoder jwtDecoder(AccessTokenService accessTokens) { return accessTokens.decoder(); }

    @Bean
    JwtEncoder jwtEncoder(AccessTokenService accessTokens) { return accessTokens.encoder(); }

    @Bean
    UserDetailsService unusedFormAuthentication() {
        return username -> { throw new UsernameNotFoundException("Password authentication is handled by the auth service"); };
    }

    @Bean
    SecurityFilterChain securityFilterChain(HttpSecurity http, JwtDecoder decoder, AuthService authService,
                                           @Qualifier("corsConfigurationSource") CorsConfigurationSource corsSource) throws Exception {
        return http
                .csrf(csrf -> csrf.disable())
                .cors(cors -> cors.configurationSource(corsSource))
                .formLogin(form -> form.disable())
                .httpBasic(basic -> basic.disable())
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers("/api/auth/login", "/api/auth/refresh", "/api/auth/logout", "/actuator/health").permitAll()
                        .requestMatchers("/api/auth/me").hasAnyAuthority(SecurityRole.allAuthorities())
                        .anyRequest().denyAll())
                .headers(headers -> headers
                        .frameOptions(frame -> frame.deny())
                        .addHeaderWriter(new StaticHeadersWriter("Content-Security-Policy",
                                "default-src 'none'; frame-ancestors 'none'; base-uri 'none'"))
                        .addHeaderWriter(new StaticHeadersWriter("Referrer-Policy", "no-referrer"))
                        .addHeaderWriter(new StaticHeadersWriter("Permissions-Policy",
                                "camera=(), microphone=(), geolocation=()")))
                .addFilterBefore(new BearerTokenFilter(decoder, authService), UsernamePasswordAuthenticationFilter.class)
                .exceptionHandling(errors -> errors
                        .authenticationEntryPoint((request, response, exception) -> {
                            response.setStatus(401);
                            response.setContentType("application/json");
                            response.getWriter().write("{\"error\":\"Unauthorized\"}");
                        })
                        .accessDeniedHandler((request, response, exception) -> {
                            response.setStatus(403);
                            response.setContentType("application/json");
                            response.getWriter().write("{\"error\":\"Forbidden\"}");
                        }))
                .build();
    }
}
