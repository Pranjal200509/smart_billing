package com.billing.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;

@Entity
@Table(name = "meters")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Meter {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "meter_number", unique = true, nullable = false, length = 30)
    private String meterNumber;

    @Column(name = "consumer_number", unique = true, nullable = false, length = 30)
    private String consumerNumber;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "installation_date")
    private LocalDate installationDate;

    @Column(name = "current_reading_kwh")
    private Double currentReadingKwh = 0.0;

    @Column(length = 20)
    private String status = "ACTIVE"; // ACTIVE, INACTIVE, FAULTY
}
