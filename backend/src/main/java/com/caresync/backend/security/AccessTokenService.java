package com.caresync.backend.security;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.oauth2.core.OAuth2Error;
import org.springframework.security.oauth2.core.OAuth2TokenValidator;
import org.springframework.security.oauth2.core.OAuth2TokenValidatorResult;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.security.oauth2.jwt.JwtException;
import org.springframework.security.oauth2.jwt.JwtTimestampValidator;
import org.springframework.security.oauth2.jwt.JwtIssuerValidator;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;
import org.springframework.security.oauth2.jwt.NimbusJwtEncoder;
import org.springframework.security.oauth2.jwt.JwsHeader;
import org.springframework.stereotype.Service;
import com.nimbusds.jose.jwk.source.ImmutableSecret;

import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.Instant;

@Service
public class AccessTokenService {
    public static final String ISSUER = "caresync";
    public static final String AUDIENCE = "caresync-api";
    public static final long LIFETIME_SECONDS = 900;

    private final JwtEncoder encoder;
    private final JwtDecoder decoder;

    public AccessTokenService(@Value("${caresync.security.jwt-secret:}") String configuredSecret) {
        byte[] secret = configuredSecret.getBytes(StandardCharsets.UTF_8);
        if (secret.length < 32) {
            throw new IllegalStateException("CARESYNC_JWT_SECRET must contain at least 32 UTF-8 bytes");
        }
        SecretKey key = new SecretKeySpec(secret, "HmacSHA256");
        this.encoder = new NimbusJwtEncoder(new ImmutableSecret<>(key));
        NimbusJwtDecoder nimbusDecoder = NimbusJwtDecoder.withSecretKey(key).macAlgorithm(MacAlgorithm.HS256).build();
        JwtTimestampValidator timestamps = new JwtTimestampValidator(Duration.ofSeconds(30));
        OAuth2TokenValidator<Jwt> claims = jwt -> {
            Instant issued = jwt.getIssuedAt();
            Instant expires = jwt.getExpiresAt();
            Object userId = jwt.getClaims().get("uid");
            Object version = jwt.getClaims().get("ver");
            Object hospital = jwt.getClaims().get("hospitalId");
            Object subject = jwt.getClaims().get("sub");
            Object name = jwt.getClaims().get("name");
            Object role = jwt.getClaims().get("role");
            boolean valid = jwt.getAudience().contains(AUDIENCE)
                    && subject instanceof String subjectValue && !subjectValue.isBlank()
                    && name instanceof String nameValue && !nameValue.isBlank()
                    && role instanceof String roleValue && SecurityRole.supports(roleValue)
                    && isInteger(userId) && ((Number) userId).longValue() > 0
                    && isInteger(version) && ((Number) version).longValue() >= 0
                    && (hospital == null || isInteger(hospital) && ((Number) hospital).longValue() > 0)
                    && issued != null && expires != null && expires.isAfter(issued)
                    && Duration.between(issued, expires).compareTo(Duration.ofSeconds(LIFETIME_SECONDS)) <= 0
                    && !issued.isAfter(Instant.now().plusSeconds(30));
            return valid ? OAuth2TokenValidatorResult.success()
                    : OAuth2TokenValidatorResult.failure(new OAuth2Error("invalid_token", "Invalid token claims", null));
        };
        nimbusDecoder.setJwtValidator(jwt -> {
            OAuth2TokenValidatorResult issuerResult = new JwtIssuerValidator(ISSUER).validate(jwt);
            if (issuerResult.hasErrors()) return issuerResult;
            OAuth2TokenValidatorResult timestampResult = timestamps.validate(jwt);
            if (timestampResult.hasErrors()) return timestampResult;
            return claims.validate(jwt);
        });
        this.decoder = nimbusDecoder;
    }

    public String issue(AuthAccount account, Long effectiveHospitalId) {
        Instant now = Instant.now();
        var claimsBuilder = org.springframework.security.oauth2.jwt.JwtClaimsSet.builder()
                .issuer(ISSUER)
                .audience(java.util.List.of(AUDIENCE))
                .subject(account.getUsername())
                .issuedAt(now)
                .expiresAt(now.plusSeconds(LIFETIME_SECONDS))
                .claim("uid", account.getId())
                .claim("name", account.getFullName())
                .claim("role", account.getRole())
                .claim("ver", account.getTokenVersion());
        if (effectiveHospitalId != null) claimsBuilder.claim("hospitalId", effectiveHospitalId);
        var claims = claimsBuilder.build();
        return encoder.encode(JwtEncoderParameters.from(JwsHeader.with(MacAlgorithm.HS256).type("JWT").build(), claims))
                .getTokenValue();
    }

    public Jwt verify(String token) throws JwtException {
        return decoder.decode(token);
    }

    public JwtDecoder decoder() { return decoder; }
    public JwtEncoder encoder() { return encoder; }

    private static boolean isInteger(Object value) {
        if (!(value instanceof Number number)) return false;
        if (number instanceof Byte || number instanceof Short || number instanceof Integer || number instanceof Long
                || number instanceof java.math.BigInteger) return true;
        if (number instanceof java.math.BigDecimal decimal) {
            try { decimal.longValueExact(); return true; }
            catch (ArithmeticException ignored) { return false; }
        }
        return false;
    }
}
