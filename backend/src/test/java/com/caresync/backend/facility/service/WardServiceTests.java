
package com.caresync.backend.facility.service;

import com.caresync.backend.facility.dto.WardRequest;
import com.caresync.backend.facility.dto.WardResponse;
import com.caresync.backend.facility.entity.Ward;
import com.caresync.backend.facility.exception.WardAlreadyExistsException;
import com.caresync.backend.facility.exception.WardNotFoundException;
import com.caresync.backend.facility.repository.WardRepository;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class WardServiceTests {

    @Mock
    private WardRepository wardRepository;

    @InjectMocks
    private WardService wardService;

    private Ward createSampleWard(Long hospitalId) {
        return new Ward(
                hospitalId,
                "General Ward",
                "GEN-01",
                "General patient ward"
        );
    }

    @Test
    void createWardSuccessfully() {
        Ward ward = createSampleWard(1L);

        when(wardRepository.existsByHospitalIdAndWardCode(1L, "GEN-01"))
                .thenReturn(false);

        when(wardRepository.save(any(Ward.class)))
                .thenReturn(ward);

        WardResponse response = wardService.createWard(
                1L,
                new WardRequest("General Ward", "GEN-01", "General patient ward")
        );

        assertEquals("General Ward", response.name());
        assertEquals("GEN-01", response.wardCode());

        verify(wardRepository).save(any(Ward.class));
    }

    @Test
    void createWardRejectsDuplicateCode() {
        when(wardRepository.existsByHospitalIdAndWardCode(1L, "GEN-01"))
                .thenReturn(true);

        assertThrows(
                WardAlreadyExistsException.class,
                () -> wardService.createWard(
                        1L,
                        new WardRequest("General Ward", "GEN-01", null)
                )
        );

        verify(wardRepository, never()).save(any(Ward.class));
    }

    @Test
    void getAllWardsSuccessfully() {
        when(wardRepository.findAllByHospitalId(1L))
                .thenReturn(List.of(createSampleWard(1L)));

        List<WardResponse> responses = wardService.getAllWards(1L);

        assertEquals(1, responses.size());
        assertEquals("General Ward", responses.get(0).name());
    }

    @Test
    void getWardByIdSuccessfully() {
        when(wardRepository.findByIdAndHospitalId(10L, 1L))
                .thenReturn(Optional.of(createSampleWard(1L)));

        WardResponse response = wardService.getWardById(1L, 10L);

        assertEquals("General Ward", response.name());
    }

    @Test
    void getWardByIdRejectsDifferentHospital() {
        when(wardRepository.findByIdAndHospitalId(10L, 2L))
                .thenReturn(Optional.empty());

        assertThrows(
                WardNotFoundException.class,
                () -> wardService.getWardById(2L, 10L)
        );
    }

    @Test
    void updateWardSuccessfully() {
        Ward ward = createSampleWard(1L);

        when(wardRepository.findByIdAndHospitalId(10L, 1L))
                .thenReturn(Optional.of(ward));

        when(wardRepository.existsByHospitalIdAndWardCodeAndIdNot(
                1L, "ICU-01", 10L
        )).thenReturn(false);

        when(wardRepository.save(any(Ward.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

        WardResponse response = wardService.updateWard(
                1L,
                10L,
                new WardRequest("Intensive Care Unit", "ICU-01", "Critical care")
        );

        assertEquals("Intensive Care Unit", response.name());
        assertEquals("ICU-01", response.wardCode());
    }

    @Test
    void updateWardRejectsDuplicateCode() {
        Ward ward = createSampleWard(1L);

        when(wardRepository.findByIdAndHospitalId(10L, 1L))
                .thenReturn(Optional.of(ward));

        when(wardRepository.existsByHospitalIdAndWardCodeAndIdNot(
                1L, "ICU-01", 10L
        )).thenReturn(true);

        assertThrows(
                WardAlreadyExistsException.class,
                () -> wardService.updateWard(
                        1L,
                        10L,
                        new WardRequest("ICU", "ICU-01", null)
                )
        );

        verify(wardRepository, never()).save(any(Ward.class));
    }

    @Test
    void deactivateWardSuccessfully() {
        Ward ward = createSampleWard(1L);

        when(wardRepository.findByIdAndHospitalId(10L, 1L))
                .thenReturn(Optional.of(ward));

        when(wardRepository.save(any(Ward.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

        WardResponse response = wardService.updateWardStatus(1L, 10L, false);

        assertFalse(response.active());
    }

    @Test
    void rejectRequestWhenHospitalIdIsNull() {
        assertThrows(
                IllegalStateException.class,
                () -> wardService.getAllWards(null)
        );

        verifyNoInteractions(wardRepository);
    }


@Test
void createWardRejectsDuplicateName() {
    when(wardRepository.existsByHospitalIdAndWardCode(1L, "GEN-02"))
            .thenReturn(false);

    when(wardRepository.existsByHospitalIdAndName(1L, "General Ward"))
            .thenReturn(true);

    assertThrows(
            WardAlreadyExistsException.class,
            () -> wardService.createWard(
                    1L,
                    new WardRequest("General Ward", "GEN-02", null)
            )
    );

    verify(wardRepository, never()).save(any(Ward.class));
}

@Test
void updateWardRejectsDuplicateName() {
    Ward ward = createSampleWard(1L);

    when(wardRepository.findByIdAndHospitalId(10L, 1L))
            .thenReturn(Optional.of(ward));

    when(wardRepository.existsByHospitalIdAndWardCodeAndIdNot(
            1L, "ICU-01", 10L
    )).thenReturn(false);

    when(wardRepository.existsByHospitalIdAndNameAndIdNot(
            1L, "Intensive Care Unit", 10L
    )).thenReturn(true);

    assertThrows(
            WardAlreadyExistsException.class,
            () -> wardService.updateWard(
                    1L,
                    10L,
                    new WardRequest("Intensive Care Unit", "ICU-01", null)
            )
    );

    verify(wardRepository, never()).save(any(Ward.class));
}

@Test
void updateWardAllowsKeepingItsOwnName() {
    Ward ward = createSampleWard(1L);

    when(wardRepository.findByIdAndHospitalId(10L, 1L))
            .thenReturn(Optional.of(ward));

    when(wardRepository.existsByHospitalIdAndWardCodeAndIdNot(
            1L, "GEN-02", 10L
    )).thenReturn(false);

    when(wardRepository.existsByHospitalIdAndNameAndIdNot(
            1L, "General Ward", 10L
    )).thenReturn(false);

    when(wardRepository.save(any(Ward.class)))
            .thenAnswer(invocation -> invocation.getArgument(0));

    WardResponse response = wardService.updateWard(
            1L,
            10L,
            new WardRequest("General Ward", "GEN-02", null)
    );

    assertEquals("General Ward", response.name());
    assertEquals("GEN-02", response.wardCode());
}

@Test
void sameWardNameIsAllowedInDifferentHospitals() {
    when(wardRepository.existsByHospitalIdAndWardCode(2L, "GEN-01"))
            .thenReturn(false);

    when(wardRepository.existsByHospitalIdAndName(2L, "General Ward"))
            .thenReturn(false);

    Ward ward = createSampleWard(2L);

    when(wardRepository.save(any(Ward.class)))
            .thenReturn(ward);

    WardResponse response = wardService.createWard(
            2L,
            new WardRequest("General Ward", "GEN-01", null)
    );

    assertEquals("General Ward", response.name());

    verify(wardRepository).save(any(Ward.class));
}

}
