package com.caresync.backend;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest(properties = {
		"caresync.security.jwt-secret=local-test-secret-change-before-deployment-123456789",
		"spring.datasource.url=jdbc:h2:mem:caresync-context-test;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE"
})
class CaresyncBackendApplicationTests {

	@Test
	void contextLoads() {
	}

}
