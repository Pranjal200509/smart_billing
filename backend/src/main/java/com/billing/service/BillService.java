package com.billing.service;

import com.billing.dto.BillDto;
import com.billing.dto.PaymentRequest;
import com.billing.entity.*;
import com.billing.exception.BadRequestException;
import com.billing.exception.ResourceNotFoundException;
import com.billing.repository.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class BillService {

    @Autowired
    private BillRepository billRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private MeterRepository meterRepository;

    @Autowired
    private MeterReadingRepository meterReadingRepository;

    @Autowired
    private PaymentRepository paymentRepository;

    @Autowired
    private NotificationRepository notificationRepository;

    private static final DateTimeFormatter MONTH_FORMATTER = DateTimeFormatter.ofPattern("MMMM yyyy");

    public List<BillDto> getBillsForUser(Long userId) {
        return billRepository.findByUserIdOrderByBillingMonthDesc(userId)
                .stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    public BillDto getCurrentBillForUser(Long userId) {
        // Return first pending bill, or latest bill if none pending
        return billRepository.findFirstByUserIdAndPaymentStatusOrderByBillingMonthDesc(userId, "PENDING")
                .map(this::convertToDto)
                .orElseGet(() -> billRepository.findFirstByUserIdOrderByBillingMonthDesc(userId)
                        .map(this::convertToDto)
                        .orElseThrow(() -> new ResourceNotFoundException("No bills found for user")));
    }

    @Transactional
    public BillDto generateBill(Long userId, LocalDate billingMonth) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        Meter meter = meterRepository.findByUserId(userId)
                .orElseThrow(() -> new ResourceNotFoundException("Meter not found for user"));

        LocalDate firstDayOfBillingMonth = billingMonth.withDayOfMonth(1);
        if (billRepository.existsByUserIdAndBillingMonth(userId, firstDayOfBillingMonth)) {
            throw new BadRequestException("Bill already generated for " + firstDayOfBillingMonth.format(MONTH_FORMATTER));
        }

        // Find the latest reading in this month (current reading)
        List<MeterReading> readings = meterReadingRepository.findByMeterIdOrderByReadingDateDesc(meter.getId());
        if (readings.isEmpty()) {
            throw new BadRequestException("No meter readings logged. Cannot calculate bill.");
        }

        // Current reading is the most recent one
        MeterReading currentReading = readings.get(0);

        // Previous reading is either the previous month's bill current reading, or 0
        Double prevReadingValue = 0.0;
        Optional<Bill> latestBillOpt = billRepository.findFirstByUserIdOrderByBillingMonthDesc(userId);
        if (latestBillOpt.isPresent()) {
            prevReadingValue = latestBillOpt.get().getCurrentReadingKwh();
        }

        Double unitsConsumed = currentReading.getReadingValue() - prevReadingValue;
        if (unitsConsumed < 0) {
            unitsConsumed = 0.0; // Fail-safe
        }

        // Perform Tariff calculations
        Double energyCharge = calculateEnergyCharge(unitsConsumed, user.getConnectionType());
        Double fixedCharge = calculateFixedCharge(user.getLoadCapacityKw(), user.getConnectionType());
        Double taxes = calculateTaxes(energyCharge, user.getConnectionType());
        Double totalAmount = energyCharge + fixedCharge + taxes;

        // Generate a clean Bill Number
        String billNumber = "EB" + billingMonth.getYear() + String.format("%02d", billingMonth.getMonthValue()) + String.format("%04d", user.getId());

        Bill bill = Bill.builder()
                .user(user)
                .billNumber(billNumber)
                .billingMonth(firstDayOfBillingMonth)
                .previousReadingKwh(prevReadingValue)
                .currentReadingKwh(currentReading.getReadingValue())
                .unitsConsumed(unitsConsumed)
                .energyCharge(energyCharge)
                .fixedCharge(fixedCharge)
                .taxes(taxes)
                .lateFee(0.0)
                .totalAmount(totalAmount)
                .dueDate(LocalDate.now().plusDays(20)) // 20 days grace period
                .paymentStatus("PENDING")
                .build();

        Bill savedBill = billRepository.save(bill);

        // Update meter reference
        meter.setCurrentReadingKwh(currentReading.getReadingValue());
        meterRepository.save(meter);

        // Dispatch alert notification
        Notification notification = Notification.builder()
                .user(user)
                .title("New Bill Generated")
                .subtitle("Your bill of ₹" + String.format("%.2f", totalAmount) + " for " + firstDayOfBillingMonth.format(MONTH_FORMATTER) + " is generated.")
                .type("Bill Generated")
                .isRead(false)
                .build();
        notificationRepository.save(notification);

        return convertToDto(savedBill);
    }

    @Transactional
    public Payment payBill(PaymentRequest request) {
        Bill bill = billRepository.findById(request.getBillId())
                .orElseThrow(() -> new ResourceNotFoundException("Bill not found"));

        if ("PAID".equals(bill.getPaymentStatus())) {
            throw new BadRequestException("Bill has already been paid.");
        }

        // Verify transaction amount matches total due
        if (request.getAmountPaid() < bill.getTotalAmount()) {
            throw new BadRequestException("Payment amount is less than total bill amount: ₹" + bill.getTotalAmount());
        }

        String transactionId = "TXN" + UUID.randomUUID().toString().replace("-", "").substring(0, 12).toUpperCase();

        Payment payment = Payment.builder()
                .bill(bill)
                .transactionId(transactionId)
                .paymentMethod(request.getPaymentMethod())
                .amountPaid(request.getAmountPaid())
                .status("SUCCESS")
                .build();

        Payment savedPayment = paymentRepository.save(payment);

        // Update bill status
        bill.setPaymentStatus("PAID");
        billRepository.save(bill);

        // Dispatch success notification
        Notification notification = Notification.builder()
                .user(bill.getUser())
                .title("Payment Successful")
                .subtitle("₹" + request.getAmountPaid() + " paid successfully for " + bill.getBillingMonth().format(MONTH_FORMATTER))
                .type("Payment Success")
                .isRead(false)
                .build();
        notificationRepository.save(notification);

        return savedPayment;
    }

    // Cron Job: Run every night at 12:00 AM to calculate overdue accounts
    @Scheduled(cron = "0 0 0 * * ?")
    @Transactional
    public void checkOverdueBills() {
        LocalDate today = LocalDate.now();
        List<Bill> pendingBills = billRepository.findByPaymentStatus("PENDING");

        for (Bill bill : pendingBills) {
            if (today.isAfter(bill.getDueDate())) {
                bill.setPaymentStatus("OVERDUE");
                Double lateFee = 150.0; // standard late fee
                bill.setLateFee(lateFee);
                bill.setTotalAmount(bill.getTotalAmount() + lateFee);
                billRepository.save(bill);

                // Notify User
                Notification notification = Notification.builder()
                        .user(bill.getUser())
                        .title("Due Date Exceeded")
                        .subtitle("Your bill " + bill.getBillNumber() + " is overdue. Late fee of ₹150 has been added.")
                        .type("Due Date Reminder")
                        .isRead(false)
                        .build();
                notificationRepository.save(notification);
            }
        }
        System.out.println("Cron: Completed overdue checking at " + LocalDateTime.now());
    }

    private Double calculateEnergyCharge(Double units, String connectionType) {
        if ("Commercial".equalsIgnoreCase(connectionType)) {
            return units * 11.0;
        } else if ("Industrial".equalsIgnoreCase(connectionType)) {
            return units * 14.0;
        } else {
            // Residential tiered logic
            if (units <= 100) {
                return units * 4.5;
            } else if (units <= 300) {
                return (100 * 4.5) + ((units - 100) * 7.0);
            } else {
                return (100 * 4.5) + (200 * 7.0) + ((units - 300) * 9.5);
            }
        }
    }

    private Double calculateFixedCharge(Double loadKw, String connectionType) {
        if ("Commercial".equalsIgnoreCase(connectionType)) {
            return loadKw * 100.0;
        } else if ("Industrial".equalsIgnoreCase(connectionType)) {
            return loadKw * 200.0;
        } else {
            return loadKw * 50.0; // Residential
        }
    }

    private Double calculateTaxes(Double energyCharge, String connectionType) {
        double rate = "Industrial".equalsIgnoreCase(connectionType) ? 0.15 : 0.10;
        return energyCharge * rate;
    }

    private BillDto convertToDto(Bill bill) {
        Meter meter = meterRepository.findByUserId(bill.getUser().getId()).orElse(null);
        return BillDto.builder()
                .id(bill.getId())
                .billNumber(bill.getBillNumber())
                .billingMonth(bill.getBillingMonth().format(MONTH_FORMATTER))
                .rawBillingMonth(bill.getBillingMonth())
                .previousReadingKwh(bill.getPreviousReadingKwh())
                .currentReadingKwh(bill.getCurrentReadingKwh())
                .unitsConsumed(bill.getUnitsConsumed())
                .energyCharge(bill.getEnergyCharge())
                .fixedCharge(bill.getFixedCharge())
                .taxes(bill.getTaxes())
                .lateFee(bill.getLateFee())
                .totalAmount(bill.getTotalAmount())
                .dueDate(bill.getDueDate())
                .paymentStatus(bill.getPaymentStatus())
                .createdAt(bill.getCreatedAt())
                .consumerNumber(meter != null ? meter.getConsumerNumber() : "N/A")
                .build();
    }
}
