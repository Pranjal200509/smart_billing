package com.billing.controller;

import com.billing.dto.ComplaintRequest;
import com.billing.entity.Complaint;
import com.billing.security.UserDetailsImpl;
import com.billing.service.ComplaintService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/complaints")
public class ComplaintController {

    @Autowired
    private ComplaintService complaintService;

    @PostMapping
    public ResponseEntity<Complaint> submitComplaint(
            @AuthenticationPrincipal UserDetailsImpl userDetails,
            @Valid @RequestBody ComplaintRequest request) {
        return ResponseEntity.ok(complaintService.submitComplaint(userDetails.getId(), request));
    }

    @GetMapping
    public ResponseEntity<List<Complaint>> getMyComplaints(@AuthenticationPrincipal UserDetailsImpl userDetails) {
        return ResponseEntity.ok(complaintService.getComplaintsForUser(userDetails.getId()));
    }
}
