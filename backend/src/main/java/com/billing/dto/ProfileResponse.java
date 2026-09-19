package com.billing.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ProfileResponse {
    private Long id;
    private String customerId;
    private String fullName;
    private String email;
    private String mobileNumber;
    private String address;
    private String city;
    private String state;
    private String pinCode;
    private String connectionType;
    private Double loadCapacityKw;
    private String status;
    
    // Meter info
    private String meterNumber;
    private String consumerNumber;
    private Double currentReadingKwh;
    private String meterStatus;
}
