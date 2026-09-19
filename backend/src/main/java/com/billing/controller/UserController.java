package com.billing.controller;

import com.billing.dto.MessageResponse;
import com.billing.dto.ProfileResponse;
import com.billing.entity.Meter;
import com.billing.entity.User;
import com.billing.exception.ResourceNotFoundException;
import com.billing.repository.MeterRepository;
import com.billing.repository.UserRepository;
import com.billing.security.UserDetailsImpl;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/user")
public class UserController {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private MeterRepository meterRepository;

    @GetMapping("/profile")
    public ResponseEntity<ProfileResponse> getProfile(@AuthenticationPrincipal UserDetailsImpl userDetails) {
        User user = userRepository.findById(userDetails.getId())
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        Meter meter = meterRepository.findByUserId(user.getId()).orElse(null);

        ProfileResponse.ProfileResponseBuilder builder = ProfileResponse.builder()
                .id(user.getId())
                .customerId(user.getCustomerId())
                .fullName(user.getFullName())
                .email(user.getEmail())
                .mobileNumber(user.getMobileNumber())
                .address(user.getAddress())
                .city(user.getCity())
                .state(user.getState())
                .pinCode(user.getPinCode())
                .connectionType(user.getConnectionType())
                .loadCapacityKw(user.getLoadCapacityKw())
                .status(user.getStatus());

        if (meter != null) {
            builder.meterNumber(meter.getMeterNumber())
                    .consumerNumber(meter.getConsumerNumber())
                    .currentReadingKwh(meter.getCurrentReadingKwh())
                    .meterStatus(meter.getStatus());
        }

        return ResponseEntity.ok(builder.build());
    }

    @PutMapping("/profile")
    public ResponseEntity<MessageResponse> updateProfile(
            @AuthenticationPrincipal UserDetailsImpl userDetails,
            @RequestBody ProfileResponse profileRequest) {
        User user = userRepository.findById(userDetails.getId())
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        user.setFullName(profileRequest.getFullName());
        user.setMobileNumber(profileRequest.getMobileNumber());
        user.setAddress(profileRequest.getAddress());
        user.setCity(profileRequest.getCity());
        user.setState(profileRequest.getState());
        user.setPinCode(profileRequest.getPinCode());

        userRepository.save(user);
        return ResponseEntity.ok(new MessageResponse("Profile updated successfully."));
    }
}
