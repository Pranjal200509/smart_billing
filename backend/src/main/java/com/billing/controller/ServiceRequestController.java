package com.billing.controller;

import com.billing.dto.ServiceRequestDto;
import com.billing.entity.ServiceRequest;
import com.billing.security.UserDetailsImpl;
import com.billing.service.ServiceRequestService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/service-requests")
public class ServiceRequestController {

    @Autowired
    private ServiceRequestService serviceRequestService;

    @PostMapping
    public ResponseEntity<ServiceRequest> submitRequest(
            @AuthenticationPrincipal UserDetailsImpl userDetails,
            @Valid @RequestBody ServiceRequestDto requestDto) {
        return ResponseEntity.ok(serviceRequestService.submitRequest(userDetails.getId(), requestDto));
    }

    @GetMapping
    public ResponseEntity<List<ServiceRequest>> getMyRequests(@AuthenticationPrincipal UserDetailsImpl userDetails) {
        return ResponseEntity.ok(serviceRequestService.getRequestsForUser(userDetails.getId()));
    }
}
