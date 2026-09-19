package com.billing.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "meter_readings")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MeterReading {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "meter_id", nullable = false)
    private Meter meter;

    @CreationTimestamp
    @Column(name = "reading_date")
    private LocalDateTime readingDate;

    @Column(name = "reading_value", nullable = false)
    private Double readingValue;

    @Column(name = "recorded_by", length = 30)
    private String recordedBy = "SYSTEM"; // SYSTEM, TECHNICIAN, USER
}
