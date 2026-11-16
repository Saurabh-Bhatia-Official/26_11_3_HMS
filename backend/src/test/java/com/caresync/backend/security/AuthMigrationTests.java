package com.caresync.backend.security;

import org.h2.jdbcx.JdbcDataSource;
import org.junit.jupiter.api.Test;
import org.springframework.core.io.ClassPathResource;
import org.springframework.jdbc.datasource.init.ScriptUtils;

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.Statement;
import java.time.Instant;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

class AuthMigrationTests {
    @Test
    void additiveMigrationPreservesExistingAuthRowsAndAddsSecuritySchema() throws Exception {
        JdbcDataSource database = new JdbcDataSource();
        database.setURL("jdbc:h2:mem:caresync-migration-isolated;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE");
        try (Connection connection = database.getConnection(); Statement sql = connection.createStatement()) {
            sql.execute("CREATE TABLE auth_accounts (id BIGINT PRIMARY KEY, username VARCHAR(64) NOT NULL)");
            sql.execute("CREATE TABLE auth_refresh_tokens (id BIGINT PRIMARY KEY, account_id BIGINT NOT NULL, token_hash VARCHAR(64) NOT NULL, expires_at TIMESTAMP WITH TIME ZONE NOT NULL, hospital_id BIGINT, revoked BOOLEAN NOT NULL)");
            sql.execute("INSERT INTO auth_accounts (id, username) VALUES (7, 'existing-user')");
            sql.execute("INSERT INTO auth_refresh_tokens (id, account_id, token_hash, expires_at, revoked) VALUES (11, 7, 'preserved-token-hash', TIMESTAMP WITH TIME ZONE '2030-01-01 00:00:00+00:00', FALSE)");

            ScriptUtils.executeSqlScript(connection, new ClassPathResource("db/migration/auth_security_hardening.sql"));

            try (ResultSet account = sql.executeQuery("SELECT username, token_version FROM auth_accounts WHERE id = 7")) {
                account.next();
                assertEquals("existing-user", account.getString("username"));
                assertEquals(0, account.getLong("token_version"));
            }
            try (ResultSet refresh = sql.executeQuery("SELECT token_hash, family_id FROM auth_refresh_tokens WHERE id = 11")) {
                refresh.next();
                assertEquals("preserved-token-hash", refresh.getString("token_hash"));
                assertNull(refresh.getString("family_id"));
            }
            try (ResultSet table = sql.executeQuery("SELECT COUNT(*) FROM security_audit_events")) {
                table.next();
                assertEquals(0, table.getInt(1));
            }
        }
    }
}
