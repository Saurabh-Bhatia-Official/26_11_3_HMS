package com.caresync.backend;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest(properties = {
		"caresync.security.jwt-secret=local-test-secret-change-before-deployment-123456789",
		"spring.datasource.url=jdbc:h2:mem:caresync-context-test;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE",
		"spring.datasource.driver-class-name=org.h2.Driver",
		"spring.jpa.database-platform=org.hibernate.dialect.H2Dialect"
})
class CaresyncBackendApplicationTests {

	@Test
	void contextLoads() {
	}

}
