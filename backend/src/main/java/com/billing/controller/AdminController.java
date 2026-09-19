package com.billing.controller;

import com.billing.dto.BillDto;
import com.billing.dto.MeterReadingRequest;
import com.billing.dto.PaymentDto;
import com.billing.dto.ProfileResponse;
import com.billing.entity.*;
import com.billing.exception.ResourceNotFoundException;
import com.billing.repository.*;
import com.billing.service.BillService;
import com.billing.service.ComplaintService;
import com.billing.service.ServiceRequestService;
import com.billing.service.UsageService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/v1/admin")
public class AdminController {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private MeterRepository meterRepository;

    @Autowired
    private BillRepository billRepository;

    @Autowired
    private PaymentRepository paymentRepository;

    @Autowired
    private ComplaintRepository complaintRepository;

    @Autowired
    private ServiceRequestRepository serviceRequestRepository;

    @Autowired
    private BillService billService;

    @Autowired
    private UsageService usageService;

    @Autowired
    private ComplaintService complaintService;

    @Autowired
    private ServiceRequestService serviceRequestService;

    // 1. User Management
    @GetMapping("/users")
    public ResponseEntity<List<ProfileResponse>> getAllUsers() {
        List<User> users = userRepository.findAll();
        List<ProfileResponse> responses = users.stream().map(u -> {
            Meter meter = meterRepository.findByUserId(u.getId()).orElse(null);
            ProfileResponse.ProfileResponseBuilder builder = ProfileResponse.builder()
                    .id(u.getId())
                    .customerId(u.getCustomerId())
                    .fullName(u.getFullName())
                    .email(u.getEmail())
                    .mobileNumber(u.getMobileNumber())
                    .address(u.getAddress())
                    .city(u.getCity())
                    .state(u.getState())
                    .pinCode(u.getPinCode())
                    .connectionType(u.getConnectionType())
                    .loadCapacityKw(u.getLoadCapacityKw())
                    .status(u.getStatus());

            if (meter != null) {
                builder.meterNumber(meter.getMeterNumber())
                        .consumerNumber(meter.getConsumerNumber())
                        .currentReadingKwh(meter.getCurrentReadingKwh())
                        .meterStatus(meter.getStatus());
            }
            return builder.build();
        }).collect(Collectors.toList());

        return ResponseEntity.ok(responses);
    }

    // 2. Reading Submission
    @PostMapping("/readings")
    public ResponseEntity<Map<String, String>> submitReading(@Valid @RequestBody MeterReadingRequest request) {
        usageService.submitReading(request, "TECHNICIAN");
        Map<String, String> response = new HashMap<>();
        response.put("message", "Meter reading logged successfully.");
        return ResponseEntity.ok(response);
    }

    // 3. Bill Generation
    @PostMapping("/bills/generate")
    public ResponseEntity<BillDto> generateBill(
            @RequestParam Long userId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate billingMonth) {
        return ResponseEntity.ok(billService.generateBill(userId, billingMonth));
    }

    // 4. Complaint Management
    @GetMapping("/complaints")
    public ResponseEntity<List<Complaint>> getAllComplaints() {
        return ResponseEntity.ok(complaintService.getAllComplaints());
    }

    @PutMapping("/complaints/{id}/resolve")
    public ResponseEntity<Complaint> resolveComplaint(
            @PathVariable Long id,
            @RequestParam String resolutionDetails,
            @RequestParam String status) {
        return ResponseEntity.ok(complaintService.resolveComplaint(id, resolutionDetails, status));
    }

    // 5. Service Request Management
    @GetMapping("/service-requests")
    public ResponseEntity<List<ServiceRequest>> getAllServiceRequests() {
        return ResponseEntity.ok(serviceRequestService.getAllRequests());
    }

    @PutMapping("/service-requests/{id}/status")
    public ResponseEntity<ServiceRequest> updateServiceRequestStatus(
            @PathVariable Long id,
            @RequestParam String status) {
        return ResponseEntity.ok(serviceRequestService.updateRequestStatus(id, status));
    }

    // 6. Revenue and Operations Reports
    @GetMapping("/reports/overview")
    public ResponseEntity<Map<String, Object>> getSystemOverview() {
        List<Bill> allBills = billRepository.findAll();
        List<Payment> allPayments = paymentRepository.findAll();

        Double totalBilled = allBills.stream().mapToDouble(Bill::getTotalAmount).sum();
        Double totalRevenue = allPayments.stream()
                .filter(p -> "SUCCESS".equalsIgnoreCase(p.getStatus()))
                .mapToDouble(Payment::getAmountPaid).sum();

        long pendingCount = allBills.stream().filter(b -> "PENDING".equalsIgnoreCase(b.getPaymentStatus())).count();
        long overdueCount = allBills.stream().filter(b -> "OVERDUE".equalsIgnoreCase(b.getPaymentStatus())).count();
        long resolvedComplaints = complaintRepository.findAll().stream().filter(c -> "RESOLVED".equalsIgnoreCase(c.getStatus())).count();
        long totalComplaints = complaintRepository.count();

        Map<String, Object> stats = new HashMap<>();
        stats.put("totalCustomers", userRepository.count() - 1); // exclude admin
        stats.put("totalBilledAmount", totalBilled);
        stats.put("totalRevenueCollected", totalRevenue);
        stats.put("pendingBillsCount", pendingCount);
        stats.put("overdueBillsCount", overdueCount);
        stats.put("complaintsStatus", resolvedComplaints + "/" + totalComplaints);
        stats.put("totalServiceRequests", serviceRequestRepository.count());

        return ResponseEntity.ok(stats);
    }

    // 7. Payments History (all)
    @GetMapping("/payments")
    public ResponseEntity<List<PaymentDto>> getAllPayments() {
        List<Payment> payments = paymentRepository.findAll();
        List<PaymentDto> dtos = payments.stream().map(p -> {
            Bill bill = p.getBill();
            User user = bill != null ? bill.getUser() : null;
            Meter meter = user != null ? meterRepository.findByUserId(user.getId()).orElse(null) : null;
            return PaymentDto.builder()
                    .id(p.getId())
                    .transactionId(p.getTransactionId())
                    .paymentMethod(p.getPaymentMethod())
                    .amountPaid(p.getAmountPaid())
                    .paymentDate(p.getPaymentDate())
                    .status(p.getStatus())
                    .billId(bill != null ? bill.getId() : null)
                    .billNumber(bill != null ? bill.getBillNumber() : null)
                    .billingMonth(bill != null ? bill.getBillingMonth().toString() : null)
                    .userId(user != null ? user.getId() : null)
                    .consumerName(user != null ? user.getFullName() : null)
                    .customerId(user != null ? user.getCustomerId() : null)
                    .consumerNumber(meter != null ? meter.getConsumerNumber() : null)
                    .build();
        }).sorted((a, b) -> b.getPaymentDate() != null && a.getPaymentDate() != null
                ? b.getPaymentDate().compareTo(a.getPaymentDate()) : 0)
          .collect(Collectors.toList());
        return ResponseEntity.ok(dtos);
    }
}
