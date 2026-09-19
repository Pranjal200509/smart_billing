package com.billing.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class RegisterRequest {
    @NotBlank
    private String fullName;

    @NotBlank
    @Email
    private String email;

    @NotBlank
    @Size(min = 10, max = 15)
    private String mobileNumber;

    @NotBlank
    private String consumerNumber;

    @NotBlank
    private String meterNumber;

    @NotBlank
    private String connectionType; // Residential, Commercial, Industrial

    @NotBlank
    private String address;

    @NotBlank
    private String city;

    @NotBlank
    private String state;

    @NotBlank
    private String pinCode;

    @NotBlank
    @Size(min = 5)
    private String password;
}
