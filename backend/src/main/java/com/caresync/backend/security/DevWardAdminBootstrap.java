
package com.caresync.backend.security;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

@Component
@Profile("dev")
public class DevWardAdminBootstrap implements CommandLineRunner {

    private final AuthAccountRepository accounts;
    private final PasswordEncoder passwords;

    @Value("${caresync.dev-ward-admin.username:}")
    private String username;

    @Value("${caresync.dev-ward-admin.password:}")
    private String password;

    @Value("${caresync.dev-ward-admin.hospital-id:42}")
    private Long hospitalId;

    public DevWardAdminBootstrap(
            AuthAccountRepository accounts,
            PasswordEncoder passwords
    ) {
        this.accounts = accounts;
        this.passwords = passwords;
    }

    @Override
    public void run(String... args) {

        if (username.isBlank() || password.length() < 12) {
            throw new IllegalStateException(
                    "Development Ward ADMIN requires a username and password of at least 12 characters"
            );
        }

        if (hospitalId == null || hospitalId <= 0) {
            throw new IllegalStateException("A valid development hospital ID is required");
        }

        var existingAccount = accounts.findByUsername(username);

if (existingAccount.isPresent()) {
    AuthAccount account = existingAccount.get();

    if (!"ADMIN".equals(account.getRole())
            || !hospitalId.equals(account.getHospitalId())) {
        throw new IllegalStateException(
                "Existing development account has an unexpected role or hospital ID"
        );
    }

    return;
}

        accounts.save(new AuthAccount(
                username,
                passwords.encode(password),
                "Ward Test Administrator",
                "ADMIN",
                hospitalId
        ));
    }
}
