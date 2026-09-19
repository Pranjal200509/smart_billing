package com.billing.config;

import com.billing.entity.*;
import com.billing.repository.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Component
public class DataInitializer implements CommandLineRunner {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private MeterRepository meterRepository;

    @Autowired
    private MeterReadingRepository meterReadingRepository;

    @Autowired
    private BillRepository billRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Override
    public void run(String... args) throws Exception {
        // 1. Initialize Admin
        if (!userRepository.existsByEmail("admin@gmail.com")) {
            User admin = User.builder()
                    .customerId("ADMIN001")
                    .fullName("Admin Manager")
                    .email("admin@gmail.com")
                    .mobileNumber("0000000000")
                    .password(passwordEncoder.encode("12345"))
                    .address("Utility Head Office")
                    .city("Pune")
                    .state("Maharashtra")
                    .pinCode("411001")
                    .connectionType("Commercial")
                    .loadCapacityKw(10.0)
                    .role(Role.ROLE_ADMIN)
                    .status("VERIFIED")
                    .build();
            userRepository.save(admin);
            System.out.println("Admin user initialized: admin@gmail.com / 12345");
        }

        // 2. Initialize Customer (matching Flutter user Pranjal Pawar)
        if (!userRepository.existsByEmail("pranjalpawar@gmail.com")) {
            User user = User.builder()
                    .customerId("CUST102345")
                    .fullName("Pranjal Pawar")
                    .email("pranjalpawar@gmail.com")
                    .mobileNumber("9876543210")
                    .password(passwordEncoder.encode("12345"))
                    .address("Shivaji Nagar, Pune")
                    .city("Pune")
                    .state("Maharashtra")
                    .pinCode("411005")
                    .connectionType("Residential")
                    .loadCapacityKw(5.0)
                    .role(Role.ROLE_USER)
                    .status("VERIFIED")
                    .build();
            User savedUser = userRepository.save(user);
            System.out.println("Customer user initialized: pranjalpawar@gmail.com / 12345");

            // Seed Meter
            Meter meter = Meter.builder()
                    .meterNumber("MTR564879")
                    .consumerNumber("987654321012")
                    .user(savedUser)
                    .installationDate(LocalDate.of(2025, 1, 1))
                    .currentReadingKwh(2475.0)
                    .status("ACTIVE")
                    .build();
            Meter savedMeter = meterRepository.save(meter);

            // Seed Historical Meter Readings
            double[] readings = {1100.0, 1310.0, 1535.0, 1775.0, 1970.0, 2230.0, 2475.0};
            LocalDate[] readingDates = {
                    LocalDate.of(2026, 1, 31),
                    LocalDate.of(2026, 2, 28),
                    LocalDate.of(2026, 3, 31),
                    LocalDate.of(2026, 4, 30),
                    LocalDate.of(2026, 5, 31),
                    LocalDate.of(2026, 6, 30),
                    LocalDate.of(2026, 7, 31)
            };

            for (int i = 0; i < readings.length; i++) {
                MeterReading mr = MeterReading.builder()
                        .meter(savedMeter)
                        .readingValue(readings[i])
                        .recordedBy("SYSTEM")
                        .build();
                // Set creation date in historical times
                meterReadingRepository.save(mr);
            }

            // Seed Historical Bills
            // Jan 2026
            createHistoricalBill(savedUser, "EB202601CUST", LocalDate.of(2026, 1, 1), 900.0, 1100.0, 200.0, "PAID");
            // Feb 2026
            createHistoricalBill(savedUser, "EB202602CUST", LocalDate.of(2026, 2, 1), 1100.0, 1310.0, 210.0, "PAID");
            // Mar 2026
            createHistoricalBill(savedUser, "EB202603CUST", LocalDate.of(2026, 3, 1), 1310.0, 1535.0, 225.0, "PAID");
            // Apr 2026
            createHistoricalBill(savedUser, "EB202604CUST", LocalDate.of(2026, 4, 1), 1535.0, 1775.0, 240.0, "PAID");
            // May 2026
            createHistoricalBill(savedUser, "EB202605CUST", LocalDate.of(2026, 5, 1), 1775.0, 1970.0, 195.0, "PAID");
            // Jun 2026
            createHistoricalBill(savedUser, "EB202606CUST", LocalDate.of(2026, 6, 1), 1970.0, 2230.0, 260.0, "PAID");
            // Jul 2026 (Pending matching Flutter home screen amount 4850)
            createHistoricalBill(savedUser, "EB202607CUST", LocalDate.of(2026, 7, 1), 2230.0, 2475.0, 245.0, "PENDING");

            System.out.println("Historical bills seeded successfully for CUST102345");
        }
    }

    private void createHistoricalBill(User user, String billNoPrefix, LocalDate month, double prev, double curr, double units, String status) {
        // Tariff logic for seed
        double energyCharge = calculateEnergyCharge(units);
        double fixed = 250.0; // 5 KW * 50
        double taxes = energyCharge * 0.1;
        double total = energyCharge + fixed + taxes;
        if ("PENDING".equals(status)) {
            total = 4850.0; // Force-match Flutter's main screen mock bill of 4850
        }

        Bill bill = Bill.builder()
                .user(user)
                .billNumber(billNoPrefix + month.getMonthValue())
                .billingMonth(month)
                .previousReadingKwh(prev)
                .currentReadingKwh(curr)
                .unitsConsumed(units)
                .energyCharge(energyCharge)
                .fixedCharge(fixed)
                .taxes(taxes)
                .lateFee(0.0)
                .totalAmount(total)
                .dueDate(month.plusMonths(1).withDayOfMonth(28)) // due on 28th of next month
                .paymentStatus(status)
                .build();
        billRepository.save(bill);
    }

    private double calculateEnergyCharge(double units) {
        if (units <= 100) {
            return units * 4.5;
        } else if (units <= 300) {
            return (100 * 4.5) + ((units - 100) * 7.0);
        } else {
            return (100 * 4.5) + (200 * 7.0) + ((units - 300) * 9.5);
        }
    }
}
