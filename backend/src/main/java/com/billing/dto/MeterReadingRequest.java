package com.billing.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;
import lombok.Data;

@Data
public class MeterReadingRequest {
    @NotNull
    private String consumerNumber;

    @NotNull
    @PositiveOrZero
    private Double readingValue;
}
