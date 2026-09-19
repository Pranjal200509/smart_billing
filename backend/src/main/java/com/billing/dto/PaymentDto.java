package com.billing.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PaymentDto {
    private Long id;
    private String transactionId;
    private String paymentMethod;
    private Double amountPaid;
    private LocalDateTime paymentDate;
    private String status;

    // Bill info
    private Long billId;
    private String billNumber;
    private String billingMonth;

    // User/Consumer info
    private Long userId;
    private String consumerName;
    private String consumerNumber;
    private String customerId;
}
