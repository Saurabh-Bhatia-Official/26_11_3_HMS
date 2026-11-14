package com.caresync.backend.security;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public final class AuthDtos {
    private AuthDtos() {}
    public record LoginRequest(@NotBlank @Size(max = 64) String username,
                               @NotBlank @Size(max = 256) String password) {
        public boolean isValid() {
            return username != null && !username.isBlank() && username.length() <= 64
                    && password != null && !password.isBlank() && password.length() <= 256;
        }
        @Override public String toString() { return "LoginRequest[credentials=<redacted>]"; }
    }
    public record RefreshRequest(@NotBlank @Size(max = 128) String refreshToken) {
        public boolean isValid() { return refreshToken != null && !refreshToken.isBlank() && refreshToken.length() <= 128; }
        @Override public String toString() { return "RefreshRequest[refreshToken=<redacted>]"; }
    }
    public record LogoutRequest(@NotBlank @Size(max = 128) String refreshToken) {
        public boolean isValid() { return refreshToken != null && !refreshToken.isBlank() && refreshToken.length() <= 128; }
        @Override public String toString() { return "LogoutRequest[refreshToken=<redacted>]"; }
    }
    public record TokenResponse(String accessToken, String refreshToken, String tokenType,
                                long expiresIn, UserResponse user) {
        @Override public String toString() {
            return "TokenResponse[accessToken=<redacted>, refreshToken=<redacted>, tokenType=" + tokenType
                    + ", expiresIn=" + expiresIn + ", user=" + user + "]";
        }
    }
    public record UserResponse(long id, String username, String fullName, String role, Long hospitalId) {
        @Override public String toString() { return "UserResponse[identity=<redacted>]"; }
    }
    public record ErrorResponse(String error) {}
}
