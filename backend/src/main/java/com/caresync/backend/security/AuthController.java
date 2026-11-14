package com.caresync.backend.security;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/auth")
public class AuthController {
    private final AuthService authService;
    public AuthController(AuthService authService) { this.authService = authService; }

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody(required = false) AuthDtos.LoginRequest request) {
        if (request == null || !request.isValid()) {
            return ResponseEntity.badRequest().body(new AuthDtos.ErrorResponse("Invalid request"));
        }
        return authService.login(request).<ResponseEntity<?>>map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(new AuthDtos.ErrorResponse("Invalid username or password")));
    }

    @PostMapping("/refresh")
    public ResponseEntity<?> refresh(@RequestBody(required = false) AuthDtos.RefreshRequest request) {
        if (request == null || !request.isValid()) {
            return ResponseEntity.badRequest().body(new AuthDtos.ErrorResponse("Invalid request"));
        }
        return authService.refresh(request.refreshToken()).<ResponseEntity<?>>map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(new AuthDtos.ErrorResponse("Invalid or expired refresh token")));
    }

    @PostMapping("/logout")
    public ResponseEntity<?> logout(@RequestBody(required = false) AuthDtos.LogoutRequest request) {
        if (request == null || !request.isValid()) {
            return ResponseEntity.badRequest().body(new AuthDtos.ErrorResponse("Invalid request"));
        }
        authService.logout(request.refreshToken());
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/me")
    public AuthDtos.UserResponse me(@AuthenticationPrincipal BearerTokenFilter.AuthPrincipal principal) {
        return new AuthDtos.UserResponse(principal.userId(), principal.username(), principal.fullName(), principal.role(), principal.hospitalId());
    }
}
