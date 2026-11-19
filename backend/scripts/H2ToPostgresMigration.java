
import java.sql.*;
import java.util.LinkedHashMap;
import java.util.Map;

public class H2ToPostgresMigration {

    private static final String H2_URL =
        "jdbc:h2:file:./data/caresyncdb;IFEXISTS=TRUE;ACCESS_MODE_DATA=r";

    private static final String PG_URL =
        "jdbc:postgresql://localhost:5432/caresync_db";

    private static final String[] TABLES = {
        "auth_accounts",
        "auth_refresh_tokens",
        "security_audit_events",
        "wards"
    };

    private static final Map<String, String[]> COLUMNS = new LinkedHashMap<>();

    static {
        COLUMNS.put("auth_accounts", new String[]{
            "id", "active", "failed_login_attempts", "full_name",
            "hospital_id", "locked_until", "password_hash",
            "role", "token_version", "username"
        });

        COLUMNS.put("auth_refresh_tokens", new String[]{
            "id", "expires_at", "family_id", "hospital_id",
            "revoked", "token_hash", "account_id"
        });

        COLUMNS.put("security_audit_events", new String[]{
            "id", "account_id", "event_type", "occurred_at"
        });

        COLUMNS.put("wards", new String[]{
            "id", "is_active", "created_at", "description",
            "hospital_id", "name", "updated_at", "uuid", "ward_code"
        });
    }

    public static void main(String[] args) throws Exception {

        String username = System.getenv("CARESYNC_DB_USERNAME");
        String password = System.getenv("CARESYNC_DB_PASSWORD");

        if (username == null || username.isBlank()
                || password == null || password.isBlank()) {
            throw new IllegalStateException(
                "Set CARESYNC_DB_USERNAME and CARESYNC_DB_PASSWORD first."
            );
        }

        try (
            Connection source = DriverManager.getConnection(H2_URL, "sa", "");
            Connection target = DriverManager.getConnection(
                PG_URL, username, password
            )
        ) {
            source.setReadOnly(true);
            target.setAutoCommit(false);

            try {
                Map<String, Long> sourceCounts = new LinkedHashMap<>();

                System.out.println("Checking source and destination...");

                for (String table : TABLES) {
                    long sourceCount = countRows(source, table);
                    long targetCount = countRows(target, table);

                    sourceCounts.put(table, sourceCount);

                    System.out.printf(
                        "%s | H2: %d | PostgreSQL: %d%n",
                        table, sourceCount, targetCount
                    );

                    if (targetCount != 0) {
                        throw new IllegalStateException(
                            "Destination table " + table
                            + " is not empty. Migration aborted."
                        );
                    }
                }

                System.out.println("\nStarting migration...");

                for (String table : TABLES) {
                    long copied = copyTable(source, target, table);

                    if (copied != sourceCounts.get(table)) {
                        throw new SQLException(
                            "Record count mismatch for " + table
                        );
                    }

                    System.out.printf(
                        "Copied %s: %d records%n", table, copied
                    );
                }

                System.out.println("\nSynchronizing identity sequences...");

                for (String table : TABLES) {
                    synchronizeSequence(target, table);
                }

                System.out.println("\nVerifying imported records...");

                for (String table : TABLES) {
                    long actual = countRows(target, table);
                    long expected = sourceCounts.get(table);

                    if (actual != expected) {
                        throw new SQLException(
                            "Verification failed for " + table
                        );
                    }

                    System.out.printf(
                        "%s verified: %d records%n", table, actual
                    );
                }

                target.commit();

                System.out.println(
                    "\nSUCCESS: Migration committed successfully."
                );

            } catch (Exception e) {
                target.rollback();
                System.err.println(
                    "\nMigration failed. PostgreSQL transaction rolled back."
                );
                throw e;
            }
        }
    }

    private static long countRows(
        Connection connection, String table
    ) throws SQLException {

        try (Statement statement = connection.createStatement();
             ResultSet rs = statement.executeQuery(
                 "SELECT COUNT(*) FROM public." + table
             )) {

            rs.next();
            return rs.getLong(1);
        }
    }

    private static long copyTable(
        Connection source, Connection target, String table
    ) throws SQLException {

        String[] columns = COLUMNS.get(table);
        String columnList = String.join(", ", columns);

        String selectSql =
            "SELECT " + columnList + " FROM " + table + " ORDER BY id";

        String placeholders = String.join(
            ", ", java.util.Collections.nCopies(columns.length, "?")
        );

        String insertSql =
            "INSERT INTO public." + table
            + " (" + columnList + ") VALUES (" + placeholders + ")";

        long copied = 0;

        try (Statement readStatement = source.createStatement();
             ResultSet rows = readStatement.executeQuery(selectSql);
             PreparedStatement insert = target.prepareStatement(insertSql)) {

            while (rows.next()) {
                for (int i = 1; i <= columns.length; i++) {
                    insert.setObject(i, rows.getObject(i));
                }

                insert.addBatch();
                copied++;

                if (copied % 500 == 0) {
                    insert.executeBatch();
                }
            }

            insert.executeBatch();
        }

        return copied;
    }

    private static void synchronizeSequence(
        Connection connection, String table
    ) throws SQLException {

        String sql =
            "SELECT setval("
            + "pg_get_serial_sequence('public." + table + "', 'id'), "
            + "COALESCE(MAX(id), 1), "
            + "MAX(id) IS NOT NULL"
            + ") FROM public." + table;

        try (Statement statement = connection.createStatement()) {
            statement.executeQuery(sql).close();
        }
    }
}
