package com.caresync.backend.security;

import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.time.Instant;
import java.util.Base64;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
public class AuthService {
    private static final long REFRESH_LIFETIME_SECONDS = 30L * 24 * 60 * 60;
    private static final String LOGIN_SUCCESS = "LOGIN_SUCCESS";
    private static final String LOGIN_FAILED = "LOGIN_FAILED";
    private static final String ACCOUNT_LOCKED = "ACCOUNT_LOCKED";
    private static final String REFRESH_SUCCESS = "REFRESH_SUCCESS";
    private static final String REFRESH_FAILED = "REFRESH_FAILED";
    private static final String REFRESH_REUSE = "REFRESH_REUSE";
    private static final String LOGOUT = "LOGOUT";
    private static final String ACCOUNT_DEACTIVATED = "ACCOUNT_DEACTIVATED";

    private final AuthAccountRepository accounts;
    private final RefreshTokenRepository refreshTokens;
    private final SecurityAuditEventRepository auditEvents;
    private final PasswordEncoder passwordEncoder;
    private final AccessTokenService accessTokens;
    private final String timingHash;
    private final SecureRandom random = new SecureRandom();

    public AuthService(AuthAccountRepository accounts, RefreshTokenRepository refreshTokens,
                       SecurityAuditEventRepository auditEvents, PasswordEncoder passwordEncoder,
                       AccessTokenService accessTokens) {
        this.accounts = accounts;
        this.refreshTokens = refreshTokens;
        this.auditEvents = auditEvents;
        this.passwordEncoder = passwordEncoder;
        this.accessTokens = accessTokens;
        this.timingHash = passwordEncoder.encode("non-user-password-timing-value");
    }

    @Transactional
    public Optional<AuthDtos.TokenResponse> login(AuthDtos.LoginRequest request) {
        String username = request.username().trim().toLowerCase();
        AuthAccount account = accounts.findByUsernameForUpdate(username).orElse(null);
        Instant now = Instant.now();
        if (account == null) {
            passwordEncoder.matches(request.password(), timingHash);
            audit(LOGIN_FAILED, null, now);
            return Optional.empty();
        }
        account.resetExpiredLockout(now);
        if (!account.isActive() || !account.hasValidHospitalScope() || !SecurityRole.supports(account.getRole())
                || (account.getLockedUntil() != null && account.getLockedUntil().isAfter(now))) {
            passwordEncoder.matches(request.password(), timingHash);
            audit(LOGIN_FAILED, account.getId(), now);
            return Optional.empty();
        }
        if (!passwordEncoder.matches(request.password(), account.getPasswordHash())) {
            account.recordFailure(now);
            audit(LOGIN_FAILED, account.getId(), now);
            if (account.getFailedLoginAttempts() == 5) audit(ACCOUNT_LOCKED, account.getId(), now);
            return Optional.empty();
        }
        account.recordSuccess();
        audit(LOGIN_SUCCESS, account.getId(), now);
        return Optional.of(issuePair(account, account.getHospitalId(), UUID.randomUUID().toString()));
    }

    @Transactional
    public Optional<AuthDtos.TokenResponse> refresh(String rawToken) {
        String tokenHash = hash(rawToken);
        Long accountId = refreshTokens.findAccountIdByTokenHash(tokenHash).orElse(null);
        if (accountId == null) {
            audit(REFRESH_FAILED, null, Instant.now());
            return Optional.empty();
        }

        AuthAccount account = accounts.findByIdForUpdate(accountId).orElse(null);
        RefreshToken old = refreshTokens.findByTokenHashForUpdate(tokenHash).orElse(null);
        Instant now = Instant.now();
        if (old == null || account == null) {
            audit(REFRESH_FAILED, null, now);
            return Optional.empty();
        }
        if (old.isRevoked()) {
            revokeFamily(old.getFamilyId());
            audit(REFRESH_REUSE, account.getId(), now);
            return Optional.empty();
        }
        if (!old.getExpiresAt().isAfter(now) || !account.isActive() || !account.hasValidHospitalScope()
                || !SecurityRole.supports(account.getRole())) {
            audit(REFRESH_FAILED, account.getId(), now);
            return Optional.empty();
        }
        if (!java.util.Objects.equals(account.getHospitalId(), old.getHospitalId())) {
            old.revoke();
            revokeFamily(old.getFamilyId());
            audit(REFRESH_FAILED, account.getId(), now);
            return Optional.empty();
        }

        String familyId = old.getFamilyId() == null ? UUID.randomUUID().toString() : old.getFamilyId();
        old.setFamilyId(familyId); // Adopt legacy active tokens into a family on first use.
        old.revoke();
        AuthDtos.TokenResponse response = issuePair(account, old.getHospitalId(), familyId);
        audit(REFRESH_SUCCESS, account.getId(), now);
        return Optional.of(response);
    }

    @Transactional
    public void logout(String rawToken) {
        String tokenHash = hash(rawToken);
        Long accountId = refreshTokens.findAccountIdByTokenHash(tokenHash).orElse(null);
        if (accountId == null) return;
        accounts.findByIdForUpdate(accountId);
        refreshTokens.findByTokenHashForUpdate(tokenHash).ifPresent(token -> {
            token.revoke();
            audit(LOGOUT, token.getAccount().getId(), Instant.now());
        });
    }

    @Transactional(readOnly = true)
    public Optional<BearerTokenFilter.AuthPrincipal> authenticate(Jwt jwt) {
        long id = ((Number) jwt.getClaims().get("uid")).longValue();
        long version = ((Number) jwt.getClaims().get("ver")).longValue();
        AuthAccount account = accounts.findById(id).orElse(null);
        if (account == null || !account.isActive() || !account.hasValidHospitalScope()
                || !SecurityRole.supports(account.getRole()) || account.getTokenVersion() != version
                || !account.getUsername().equals(jwt.getSubject())) return Optional.empty();

        Object hospitalValue = jwt.getClaims().get("hospitalId");
        Long claimHospital = hospitalValue instanceof Number number ? number.longValue() : null;
        if (!java.util.Objects.equals(account.getHospitalId(), claimHospital)) return Optional.empty();
        if (!account.getRole().equals(jwt.getClaimAsString("role"))) return Optional.empty();
        return Optional.of(new BearerTokenFilter.AuthPrincipal(account.getId(), account.getUsername(), account.getFullName(),
                account.getRole(), account.getHospitalId()));
    }

    @Transactional
    public boolean deactivateAccount(long accountId) {
        AuthAccount account = accounts.findByIdForUpdate(accountId).orElse(null);
        if (account == null || !account.isActive()) return false;
        account.deactivate();
        audit(ACCOUNT_DEACTIVATED, account.getId(), Instant.now());
        return true;
    }

    private void revokeFamily(String familyId) {
        if (familyId == null) return;
        List<RefreshToken> family = refreshTokens.findAllByFamilyId(familyId);
        family.forEach(RefreshToken::revoke);
    }

    private AuthDtos.TokenResponse issuePair(AuthAccount account, Long hospitalId, String familyId) {
        byte[] bytes = new byte[32];
        random.nextBytes(bytes);
        String refresh = Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
        refreshTokens.save(new RefreshToken(account, hash(refresh), Instant.now().plusSeconds(REFRESH_LIFETIME_SECONDS), hospitalId, familyId));
        return new AuthDtos.TokenResponse(accessTokens.issue(account, hospitalId), refresh, "Bearer", AccessTokenService.LIFETIME_SECONDS,
                new AuthDtos.UserResponse(account.getId(), account.getUsername(), account.getFullName(), account.getRole(), hospitalId));
    }

    private void audit(String eventType, Long accountId, Instant at) {
        auditEvents.save(new SecurityAuditEvent(eventType, accountId, at));
    }

    private static String hash(String token) {
        try {
            byte[] digest = MessageDigest.getInstance("SHA-256").digest(token.getBytes(StandardCharsets.UTF_8));
            return java.util.HexFormat.of().formatHex(digest);
        } catch (Exception e) { throw new IllegalStateException(e); }
    }
}
