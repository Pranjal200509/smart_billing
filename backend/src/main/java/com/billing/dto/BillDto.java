package com.billing.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class BillDto {
    private Long id;
    private String billNumber;
    private String billingMonth;
    private LocalDate rawBillingMonth;
    private Double previousReadingKwh;
    private Double currentReadingKwh;
    private Double unitsConsumed;
    private Double energyCharge;
    private Double fixedCharge;
    private Double taxes;
    private Double lateFee;
    private Double totalAmount;
    private LocalDate dueDate;
    private String paymentStatus;
    private LocalDateTime createdAt;
    private String consumerNumber;
}
