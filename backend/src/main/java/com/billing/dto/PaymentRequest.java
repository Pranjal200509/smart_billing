package com.billing.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.Data;

@Data
public class PaymentRequest {
    @NotNull
    private Long billId;

    @NotBlank
    private String paymentMethod;

    @NotNull
    @Positive
    private Double amountPaid;
}
