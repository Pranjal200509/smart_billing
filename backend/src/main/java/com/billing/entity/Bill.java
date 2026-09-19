package com.billing.entity;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "bills")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
public class Bill {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    @JsonIgnoreProperties({"hibernateLazyInitializer", "handler", "password"})
    private User user;

    @Column(name = "bill_number", unique = true, nullable = false, length = 30)
    private String billNumber;

    @Column(name = "billing_month", nullable = false)
    private LocalDate billingMonth;

    @Column(name = "previous_reading_kwh", nullable = false)
    private Double previousReadingKwh;

    @Column(name = "current_reading_kwh", nullable = false)
    private Double currentReadingKwh;

    @Column(name = "units_consumed", nullable = false)
    private Double unitsConsumed;

    @Column(name = "energy_charge", nullable = false)
    private Double energyCharge;

    @Column(name = "fixed_charge", nullable = false)
    private Double fixedCharge;

    @Column(nullable = false)
    private Double taxes;

    @Column(name = "late_fee")
    private Double lateFee = 0.0;

    @Column(name = "total_amount", nullable = false)
    private Double totalAmount;

    @Column(name = "due_date", nullable = false)
    private LocalDate dueDate;

    @Column(name = "payment_status", length = 20)
    private String paymentStatus = "PENDING"; // PENDING, PAID, OVERDUE

    @CreationTimestamp
    @Column(name = "created_at")
    private LocalDateTime createdAt;
}
