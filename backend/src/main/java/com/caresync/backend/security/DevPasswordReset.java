package com.caresync.backend.security;

import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

@Component
@Profile("postgres")
public class DevPasswordReset implements CommandLineRunner {

    private final AuthAccountRepository accounts;
    private final PasswordEncoder passwordEncoder;

    public DevPasswordReset(
            AuthAccountRepository accounts,
            PasswordEncoder passwordEncoder) {
        this.accounts = accounts;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    @Transactional
    public void run(String... args) {
        AuthAccount account = accounts.findByUsernameForUpdate("superadmin")
                .orElseThrow(() ->
                        new IllegalStateException("Superadmin account not found"));

        account.resetPasswordHash(
                passwordEncoder.encode("SuperAdmin@1234")
        );

        System.out.println("Development SuperAdmin password reset successfully.");
    }
}