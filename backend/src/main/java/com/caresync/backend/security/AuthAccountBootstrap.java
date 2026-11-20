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
        if (accounts.count() != 0) {
            log.info("Auth accounts already exist; skipping initial provisioning");
            return;
        }

        if (username.isBlank() && password.isBlank()) {
            // Seed standard CareSync demo accounts for local development
            log.info("Provisioning default CareSync accounts (SuperAdmin, Admin, Doctor, Nurse, Staff, Lab, Pharmacy)...");
            accounts.save(new AuthAccount("superadmin", passwords.encode("SuperAdmin@1234"), "Super Administrator", "SUPER_ADMIN", null));
            accounts.save(new AuthAccount("admin", passwords.encode("Admin@1234"), "Hospital Administrator", "ADMIN", 1L));
            accounts.save(new AuthAccount("doctor", passwords.encode("Doctor@1234"), "Duty Doctor", "DOCTOR", 1L));
            accounts.save(new AuthAccount("nurse", passwords.encode("Nurse@1234"), "Staff Nurse", "NURSE", 1L));
            accounts.save(new AuthAccount("reception", passwords.encode("Reception@1234"), "Front Desk Receptionist", "RECEPTIONIST", 1L));
            accounts.save(new AuthAccount("staff", passwords.encode("Staff@1234"), "General Staff Member", "STAFF", 1L));
            accounts.save(new AuthAccount("pharmacy", passwords.encode("Pharmacy@1234"), "Chief Pharmacist", "PHARMACIST", 1L));
            accounts.save(new AuthAccount("lab", passwords.encode("Lab@1234"), "Laboratory Technician", "LAB_TECHNICIAN", 1L));
            accounts.save(new AuthAccount("accounts", passwords.encode("Accounts@1234"), "Billing & Accounts Officer", "ACCOUNTS", 1L));
            log.info("Default CareSync demo accounts created successfully");
            return;
        }

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
        String role = scopedHospitalId == null ? "SUPER_ADMIN" : "ADMIN";
        accounts.save(new AuthAccount(username, passwords.encode(password), fullName, role, scopedHospitalId));
        log.info("Initial {} account created; remove bootstrap credentials from the environment", role);
    }
}
