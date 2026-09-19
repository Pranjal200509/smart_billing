package com.billing.entity;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "users")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
public class User {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "customer_id", unique = true, length = 50)
    private String customerId;

    @Column(name = "full_name", nullable = false)
    private String fullName;

    @Column(unique = true, nullable = false)
    private String email;

    @Column(name = "mobile_number", unique = true, nullable = false, length = 15)
    private String mobileNumber;

    @JsonIgnore
    @Column(name = "password_hash", nullable = false)
    private String password;

    @Column(columnDefinition = "TEXT")
    private String address;

    private String city;

    private String state;

    @Column(name = "pin_code", length = 10)
    private String pinCode;

    @Column(name = "connection_type", length = 20)
    private String connectionType; // "Residential", "Commercial", "Industrial"

    @Column(name = "load_capacity_kw")
    private Double loadCapacityKw = 5.0;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private Role role; // ROLE_USER, ROLE_ADMIN

    @Column(length = 20)
    private String status = "VERIFIED"; // VERIFIED, PENDING, SUSPENDED

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
