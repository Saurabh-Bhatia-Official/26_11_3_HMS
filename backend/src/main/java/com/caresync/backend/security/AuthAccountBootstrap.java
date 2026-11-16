package com.caresync.backend.security;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

@Component
public class AuthAccountBootstrap implements CommandLineRunner {
    private static final Logger log = LoggerFactory.getLogger(AuthAccountBootstrap.class);
    private final AuthAccountRepository accounts;
    private final PasswordEncoder passwords;
    private final String username;
    private final String password;
    private final String fullName;
    private final String hospitalId;

    public AuthAccountBootstrap(AuthAccountRepository accounts, PasswordEncoder passwords,
            @Value("${caresync.bootstrap.username:}") String username,
            @Value("${caresync.bootstrap.password:}") String password,
            @Value("${caresync.bootstrap.full-name:Platform Administrator}") String fullName,
            @Value("${caresync.bootstrap.hospital-id:}") String hospitalId) {
        this.accounts = accounts;
        this.passwords = passwords;
        this.username = username;
        this.password = password;
        this.fullName = fullName;
        this.hospitalId = hospitalId;
    }

    @Override
    public void run(String... args) {
        if (username.isBlank() && password.isBlank()) return;
        if (username.isBlank() || password.length() < 12) {
            throw new IllegalStateException("Bootstrap requires a username and a password of at least 12 characters");
        }
        Long scopedHospitalId = null;
        if (!hospitalId.isBlank()) {
            try {
                scopedHospitalId = Long.parseLong(hospitalId);
            } catch (NumberFormatException exception) {
                throw new IllegalStateException("CARESYNC_BOOTSTRAP_HOSPITAL_ID must be a positive integer", exception);
            }
            if (scopedHospitalId <= 0) {
                throw new IllegalStateException("CARESYNC_BOOTSTRAP_HOSPITAL_ID must be a positive integer");
            }
        }
        if (accounts.count() != 0) {
            log.info("Bootstrap admin was not created because an auth account already exists");
            return;
        }
        String role = scopedHospitalId == null ? "SUPER_ADMIN" : "ADMIN";
        accounts.save(new AuthAccount(username, passwords.encode(password), fullName, role, scopedHospitalId));
        log.info("Initial {} account created; remove bootstrap credentials from the environment", role);
    }
}
