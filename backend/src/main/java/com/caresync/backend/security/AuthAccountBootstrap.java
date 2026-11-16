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

    public AuthAccountBootstrap(AuthAccountRepository accounts, PasswordEncoder passwords,
            @Value("${caresync.bootstrap.username:}") String username,
            @Value("${caresync.bootstrap.password:}") String password,
            @Value("${caresync.bootstrap.full-name:Platform Administrator}") String fullName) {
        this.accounts = accounts; this.passwords = passwords;
        this.username = username; this.password = password; this.fullName = fullName;
    }

    @Override
    public void run(String... args) {
        if (username.isBlank() && password.isBlank()) return;
        if (username.isBlank() || password.length() < 12) {
            throw new IllegalStateException("Bootstrap requires a username and a password of at least 12 characters");
        }
        if (accounts.count() != 0) {
            log.info("Bootstrap admin was not created because an auth account already exists");
            return;
        }
        accounts.save(new AuthAccount(username, passwords.encode(password), fullName, "SUPER_ADMIN", null));
        log.info("Initial platform administrator account created; remove bootstrap credentials from the environment");
    }
}
