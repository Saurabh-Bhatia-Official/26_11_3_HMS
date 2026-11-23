package com.caresync.backend;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;

import static org.junit.jupiter.api.Assertions.assertEquals;

@SpringBootTest(properties = {
        "caresync.security.jwt-secret=local-sqlite-test-secret-change-before-deployment",
        "spring.datasource.url=jdbc:sqlite:file:caresync-test?mode=memory&cache=shared",
        "spring.datasource.driver-class-name=org.sqlite.JDBC",
        "spring.datasource.hikari.maximum-pool-size=1",
        "spring.jpa.database-platform=org.hibernate.community.dialect.SQLiteDialect",
        "spring.jpa.hibernate.ddl-auto=create-drop"
})
class SqlitePersistenceTests {
    @Autowired JdbcTemplate jdbc;

    @Test
    void createsModuleTablesInSqlite() {
        Integer tableCount = jdbc.queryForObject(
                "select count(*) from sqlite_master where type = 'table' and name in ('staff', 'invoices', 'medicines', 'lab_orders')",
                Integer.class);
        assertEquals(4, tableCount);
    }
}
