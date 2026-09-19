package com.billing.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class ComplaintRequest {
    @NotBlank
    private String complaintType;

    @NotBlank
    private String description;
}
