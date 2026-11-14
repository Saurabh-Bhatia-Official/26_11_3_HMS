package com.caresync.backend.security;

import java.util.Arrays;
import java.util.Set;
import java.util.stream.Collectors;

/** Existing account roles accepted by authentication. Operation permissions must be assigned per endpoint. */
public enum SecurityRole {
    SUPER_ADMIN,
    ADMIN,
    DOCTOR,
    NURSE,
    RECEPTIONIST,
    PHARMACIST,
    LAB_TECHNICIAN,
    ACCOUNTS,
    STAFF;

    private static final Set<String> NAMES = Arrays.stream(values())
            .map(Enum::name)
            .collect(Collectors.toUnmodifiableSet());
    private static final String[] AUTHORITIES = Arrays.stream(values())
            .map(SecurityRole::authority)
            .toArray(String[]::new);

    public String authority() {
        return "ROLE_" + name();
    }

    public static boolean supports(String role) {
        return NAMES.contains(role);
    }

    public static String[] allAuthorities() {
        return AUTHORITIES.clone();
    }
}
