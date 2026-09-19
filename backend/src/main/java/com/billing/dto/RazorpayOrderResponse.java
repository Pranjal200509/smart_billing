package com.billing.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RazorpayOrderResponse {
    private String orderId;
    private Long amount; // in paise
    private String currency;
    private String keyId;
    private Long billId;
    private Double billAmount; // in Rupees
    private String customerName;
    private String customerEmail;
    private String customerPhone;
    private String description;
    private Boolean isSandbox;
}
