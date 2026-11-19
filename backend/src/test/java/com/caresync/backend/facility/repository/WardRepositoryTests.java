
package com.caresync.backend.facility.repository;

import com.caresync.backend.facility.entity.Ward;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.data.jpa.test.autoconfigure.DataJpaTest;

import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;

@DataJpaTest(properties = {
        "spring.datasource.url=jdbc:h2:mem:caresync-ward-repository-test;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE"
})
class WardRepositoryTests {

    @Autowired
    private WardRepository wardRepository;

    @Test
    void saveWardSuccessfully() {
        Ward ward = new Ward(
                1L,
                "General Ward",
                "GEN-01",
                "General patient ward"
        );

        Ward savedWard = wardRepository.saveAndFlush(ward);

        assertNotNull(savedWard.getId());
        assertEquals("General Ward", savedWard.getName());
        assertEquals(1L, savedWard.getHospitalId());
    }

    @Test
    void findAllWardsByHospitalId() {
        wardRepository.saveAndFlush(
                new Ward(1L, "General Ward", "GEN-01", null)
        );

        wardRepository.saveAndFlush(
                new Ward(1L, "ICU", "ICU-01", null)
        );

        wardRepository.saveAndFlush(
                new Ward(2L, "Private Ward", "PVT-01", null)
        );

        List<Ward> wards = wardRepository.findAllByHospitalId(1L);

        assertEquals(2, wards.size());
    }

    @Test
    void findWardByIdAndHospitalId() {
        Ward savedWard = wardRepository.saveAndFlush(
                new Ward(1L, "General Ward", "GEN-01", null)
        );

        Optional<Ward> result = wardRepository.findByIdAndHospitalId(
                savedWard.getId(), 1L
        );

        assertTrue(result.isPresent());
        assertEquals("General Ward", result.get().getName());
    }

    @Test
    void wardCannotBeFoundUnderDifferentHospital() {
        Ward savedWard = wardRepository.saveAndFlush(
                new Ward(1L, "General Ward", "GEN-01", null)
        );

        Optional<Ward> result = wardRepository.findByIdAndHospitalId(
                savedWard.getId(), 2L
        );

        assertTrue(result.isEmpty());
    }

    @Test
    void wardCodeMustBeUniqueWithinHospital() {
        wardRepository.saveAndFlush(
                new Ward(1L, "General Ward", "GEN-01", null)
        );

        assertTrue(
                wardRepository.existsByHospitalIdAndWardCode(1L, "GEN-01")
        );

        assertFalse(
                wardRepository.existsByHospitalIdAndWardCode(2L, "GEN-01")
        );
    }

    @Test
    void sameWardCodeCanExistInDifferentHospitals() {
        wardRepository.saveAndFlush(
                new Ward(1L, "General Ward", "GEN-01", null)
        );

        Ward secondWard = wardRepository.saveAndFlush(
                new Ward(2L, "General Ward", "GEN-01", null)
        );

        assertNotNull(secondWard.getId());
    }
}
