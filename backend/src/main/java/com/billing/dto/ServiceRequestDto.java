package com.billing.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class ServiceRequestDto {
    @NotBlank
    private String requestType;

    @NotBlank
    private String details;
}
