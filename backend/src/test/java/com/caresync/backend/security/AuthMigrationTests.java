package com.caresync.backend.security;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.Arrays;
import java.util.List;
import java.util.UUID;

import org.flywaydb.core.Flyway;
import org.flywaydb.core.api.MigrationState;
import org.h2.jdbcx.JdbcDataSource;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import org.junit.jupiter.api.Test;
import org.springframework.core.io.ClassPathResource;
import org.springframework.jdbc.datasource.init.ScriptUtils;

class AuthMigrationTests {
    @Test
    void archivedHardeningScriptPreservesExistingAuthRows() throws Exception {
        JdbcDataSource database = new JdbcDataSource();
        database.setURL("jdbc:h2:mem:caresync_archived_hardening_" + UUID.randomUUID().toString().replace("-", "")
                + ";DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE");
        try (Connection connection = database.getConnection(); Statement sql = connection.createStatement()) {
            sql.execute("CREATE TABLE auth_accounts (id BIGINT PRIMARY KEY, username VARCHAR(64) NOT NULL)");
            sql.execute("CREATE TABLE auth_refresh_tokens (id BIGINT PRIMARY KEY, account_id BIGINT NOT NULL, "
                    + "token_hash VARCHAR(64) NOT NULL, expires_at TIMESTAMP WITH TIME ZONE NOT NULL, "
                    + "hospital_id BIGINT, revoked BOOLEAN NOT NULL)");
            sql.execute("INSERT INTO auth_accounts (id, username) VALUES (7, 'existing-user')");
            sql.execute("INSERT INTO auth_refresh_tokens (id, account_id, token_hash, expires_at, revoked) "
                    + "VALUES (11, 7, 'preserved-token-hash', TIMESTAMP WITH TIME ZONE '2030-01-01 00:00:00+00:00', FALSE)");

            ScriptUtils.executeSqlScript(connection,
                    new ClassPathResource("db/migration-archive/auth_security_hardening.sql.reference"));

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

    @Test
    void appliesVersionedMigrationsInOrderToIsolatedH2ForCompatibilityChecking() throws Exception {
        String databaseUrl = "jdbc:h2:mem:caresync_flyway_" + UUID.randomUUID().toString().replace("-", "")
                + ";DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE";

        Flyway flyway = Flyway.configure()
                .dataSource(databaseUrl, "sa", "")
                .locations("classpath:db/migration")
                .load();
        flyway.migrate();

        List<String> versions = Arrays.stream(flyway.info().all())
                .filter(migration -> migration.getState() == MigrationState.SUCCESS)
                .map(migration -> migration.getVersion().getVersion())
                .toList();
        assertEquals(List.of("1", "2", "3", "4"), versions);

        try (Connection connection = DriverManager.getConnection(databaseUrl, "sa", "");
             Statement statement = connection.createStatement()) {
            for (String table : List.of("HOSPITALS", "AUTH_ACCOUNTS", "AUTH_REFRESH_TOKENS",
                    "SECURITY_AUDIT_EVENTS", "HOSPITAL_MEMBERSHIPS", "MEMBERSHIP_AUDIT_EVENTS", "PATIENTS")) {
                try (ResultSet result = statement.executeQuery(
                        "SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = '" + table + "'")) {
                    result.next();
                    assertEquals(1, result.getInt(1), "Expected migrated table " + table);
                }
            }

            assertTrue(sequenceExists(statement, "HOSPITAL_PUBLIC_ID_SEQUENCE"));
            assertTrue(sequenceExists(statement, "PATIENT_ID_SEQUENCE"));
        }
    }

    private static boolean sequenceExists(Statement statement, String name) throws Exception {
        try (ResultSet result = statement.executeQuery(
                "SELECT COUNT(*) FROM INFORMATION_SCHEMA.SEQUENCES WHERE SEQUENCE_NAME = '" + name + "'")) {
            result.next();
            return result.getInt(1) == 1;
        }
    }
}
