
package com.caresync.backend.security;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

@Component
public class AuthAccountBootstrap implements CommandLineRunner {

    private static final Logger log =
            LoggerFactory.getLogger(AuthAccountBootstrap.class);

    private final AuthAccountRepository accounts;
    private final PasswordEncoder passwords;
    private final String username;
    private final String password;

    public AuthAccountBootstrap(
            AuthAccountRepository accounts,
            PasswordEncoder passwords,
            @Value("${caresync.bootstrap.username:}") String username,
            @Value("${caresync.bootstrap.password:}") String password) {

        this.accounts = accounts;
        this.passwords = passwords;
        this.username = username;
        this.password = password;
    }

    @Override
    @Transactional
    public void run(String... args) {

        if (username.isBlank() && password.isBlank()) {
            return;
        }

        if (!"superadmin".equalsIgnoreCase(username.trim())
                || password.length() < 12) {
            throw new IllegalStateException(
                    "Password reset requires username superadmin and a password of at least 12 characters");
        }

        AuthAccount account = accounts
                .findByUsernameForUpdate("superadmin")
                .orElseThrow(() -> new IllegalStateException(
                        "Existing superadmin account was not found"));

        if (!"SUPER_ADMIN".equals(account.getRole())
                || account.getHospitalId() != null
                || !account.isActive()) {
            throw new IllegalStateException(
                    "The superadmin account failed security validation");
        }

        account.resetPasswordHash(passwords.encode(password));
        accounts.save(account);

        log.info("Existing superadmin password reset successfully. Remove bootstrap credentials and restart.");
    }
}
