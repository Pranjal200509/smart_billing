package com.billing.controller;

import com.billing.dto.BillDto;
import com.billing.dto.PaymentRequest;
import com.billing.entity.Payment;
import com.billing.security.UserDetailsImpl;
import com.billing.service.BillService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/bills")
public class BillController {

    @Autowired
    private BillService billService;

    @Autowired
    private com.billing.service.RazorpayService razorpayService;

    @GetMapping("/history")
    public ResponseEntity<List<BillDto>> getBillsHistory(@AuthenticationPrincipal UserDetailsImpl userDetails) {
        return ResponseEntity.ok(billService.getBillsForUser(userDetails.getId()));
    }

    @GetMapping("/current")
    public ResponseEntity<BillDto> getCurrentBill(@AuthenticationPrincipal UserDetailsImpl userDetails) {
        return ResponseEntity.ok(billService.getCurrentBillForUser(userDetails.getId()));
    }

    @PostMapping("/pay")
    public ResponseEntity<Payment> payBill(
            @AuthenticationPrincipal UserDetailsImpl userDetails,
            @Valid @RequestBody PaymentRequest request) {
        // Validation to check that the paid bill belongs to user details can be done here or in service
        return ResponseEntity.ok(billService.payBill(request));
    }

    @PostMapping("/razorpay/create-order")
    public ResponseEntity<com.billing.dto.RazorpayOrderResponse> createRazorpayOrder(
            @AuthenticationPrincipal UserDetailsImpl userDetails,
            @Valid @RequestBody com.billing.dto.RazorpayOrderRequest request) {
        return ResponseEntity.ok(razorpayService.createOrder(request.getBillId(), userDetails.getId()));
    }

    @PostMapping("/razorpay/verify-payment")
    public ResponseEntity<Payment> verifyRazorpayPayment(
            @AuthenticationPrincipal UserDetailsImpl userDetails,
            @Valid @RequestBody com.billing.dto.RazorpayVerificationRequest request) {
        return ResponseEntity.ok(razorpayService.verifyAndCompletePayment(request, userDetails.getId()));
    }
}

