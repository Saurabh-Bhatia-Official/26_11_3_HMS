
package com.caresync.backend.facility.controller;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.caresync.backend.facility.dto.RoomRequest;
import com.caresync.backend.facility.dto.RoomResponse;
import com.caresync.backend.facility.dto.RoomStatusUpdateRequest;
import com.caresync.backend.facility.service.RoomService;
import com.caresync.backend.security.BearerTokenFilter.AuthPrincipal;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/v1/facilities/rooms")
public class RoomController {

    private final RoomService roomService;

    public RoomController(RoomService roomService) {
        this.roomService = roomService;
    }

    @PostMapping
    public ResponseEntity<RoomResponse> createRoom(
            @AuthenticationPrincipal AuthPrincipal principal,
            @Valid @RequestBody RoomRequest request
    ) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(roomService.createRoom(
                        getHospitalId(principal), request
                ));
    }

    @GetMapping
    public ResponseEntity<List<RoomResponse>> getAllRooms(
            @AuthenticationPrincipal AuthPrincipal principal,
            @RequestParam(required = false) Long wardId
    ) {
        return ResponseEntity.ok(
                roomService.getAllRooms(
                        getHospitalId(principal), wardId
                )
        );
    }

    @GetMapping("/{roomId}")
    public ResponseEntity<RoomResponse> getRoomById(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long roomId
    ) {
        return ResponseEntity.ok(
                roomService.getRoomById(
                        getHospitalId(principal), roomId
                )
        );
    }

    @PutMapping("/{roomId}")
    public ResponseEntity<RoomResponse> updateRoom(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long roomId,
            @Valid @RequestBody RoomRequest request
    ) {
        return ResponseEntity.ok(
                roomService.updateRoom(
                        getHospitalId(principal), roomId, request
                )
        );
    }

    @PatchMapping("/{roomId}/status")
    public ResponseEntity<RoomResponse> updateRoomStatus(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long roomId,
            @Valid @RequestBody RoomStatusUpdateRequest request
    ) {
        return ResponseEntity.ok(
                roomService.updateRoomStatus(
                        getHospitalId(principal),
                        roomId,
                        request.active()
                )
        );
    }

    private Long getHospitalId(AuthPrincipal principal) {
        if (principal == null || principal.hospitalId() == null) {
            throw new org.springframework.web.server.ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "No hospital is associated with the authenticated user"
            );
        }

        return principal.hospitalId();
    }
}
