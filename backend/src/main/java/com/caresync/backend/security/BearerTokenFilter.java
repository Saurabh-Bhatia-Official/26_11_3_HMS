package com.caresync.backend.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtException;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.List;

public class BearerTokenFilter extends OncePerRequestFilter {
    private final JwtDecoder decoder;
    private final AuthService authService;
    public BearerTokenFilter(JwtDecoder decoder, AuthService authService) {
        this.decoder = decoder;
        this.authService = authService;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {
        String header = request.getHeader("Authorization");
        if (header != null && header.startsWith("Bearer ")) {
            try {
                Jwt jwt = decoder.decode(header.substring(7));
                AuthPrincipal principal = authService.authenticate(jwt).orElse(null);
                if (principal != null) {
                    var authentication = new UsernamePasswordAuthenticationToken(principal, null,
                            List.of(new org.springframework.security.core.authority.SimpleGrantedAuthority(
                                    SecurityRole.valueOf(principal.role()).authority())));
                    SecurityContextHolder.getContext().setAuthentication(authentication);
                }
            } catch (JwtException ignored) {
                SecurityContextHolder.clearContext();
            }
        }
        chain.doFilter(request, response);
    }
    public record AuthPrincipal(long userId, String username, String fullName, String role, Long hospitalId) {}
}
