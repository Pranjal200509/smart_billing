package com.billing.service;

import com.billing.dto.RazorpayOrderResponse;
import com.billing.dto.RazorpayVerificationRequest;
import com.billing.entity.Bill;
import com.billing.entity.Notification;
import com.billing.entity.Payment;
import com.billing.entity.User;
import com.billing.exception.BadRequestException;
import com.billing.exception.ResourceNotFoundException;
import com.billing.repository.BillRepository;
import com.billing.repository.NotificationRepository;
import com.billing.repository.PaymentRepository;
import com.razorpay.Order;
import com.razorpay.RazorpayClient;
import com.razorpay.Utils;
import org.json.JSONObject;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.format.DateTimeFormatter;
import java.util.UUID;

@Service
public class RazorpayService {

    private static final Logger log = LoggerFactory.getLogger(RazorpayService.class);
    private static final DateTimeFormatter MONTH_FORMATTER = DateTimeFormatter.ofPattern("MMM yyyy");

    @Value("${razorpay.key-id}")
    private String keyId;

    @Value("${razorpay.key-secret}")
    private String keySecret;

    @Value("${razorpay.currency:INR}")
    private String currency;

    @Autowired
    private BillRepository billRepository;

    @Autowired
    private PaymentRepository paymentRepository;

    @Autowired
    private NotificationRepository notificationRepository;

    public RazorpayOrderResponse createOrder(Long billId, Long userId) {
        Bill bill = billRepository.findById(billId)
                .orElseThrow(() -> new ResourceNotFoundException("Bill not found with id: " + billId));

        if ("PAID".equalsIgnoreCase(bill.getPaymentStatus())) {
            throw new BadRequestException("This bill has already been paid.");
        }

        User user = bill.getUser();
        long amountInPaise = Math.round(bill.getTotalAmount() * 100);
        String orderId = null;

        // Attempt official Razorpay order creation
        if (keyId != null && !keyId.contains("placeholder") && keySecret != null && !keySecret.contains("placeholder")) {
            try {
                RazorpayClient client = new RazorpayClient(keyId, keySecret);
                JSONObject orderReq = new JSONObject();
                orderReq.put("amount", amountInPaise);
                orderReq.put("currency", currency);
                orderReq.put("receipt", "bill_" + billId + "_" + System.currentTimeMillis());

                JSONObject notes = new JSONObject();
                notes.put("billId", billId);
                notes.put("customerId", user.getCustomerId());
                notes.put("month", bill.getBillingMonth().toString());
                orderReq.put("notes", notes);

                Order order = client.orders.create(orderReq);
                orderId = order.get("id");
                log.info("Created Razorpay Order {} for Bill #{}", orderId, billId);
            } catch (Exception e) {
                log.warn("Razorpay API live call failed ({}); falling back to sandbox order", e.getMessage());
            }
        }

        // Sandbox/Fallback Order ID if live call wasn't active
        boolean isSandbox = false;
        if (orderId == null) {
            isSandbox = true;
            orderId = "order_" + UUID.randomUUID().toString().replace("-", "").substring(0, 14);
            log.info("Generated Sandbox Razorpay Order {} for Bill #{}", orderId, billId);
        }

        return RazorpayOrderResponse.builder()
                .orderId(orderId)
                .amount(amountInPaise)
                .currency(currency)
                .keyId(keyId)
                .billId(bill.getId())
                .billAmount(bill.getTotalAmount())
                .customerName(user.getFullName())
                .customerEmail(user.getEmail())
                .customerPhone(user.getMobileNumber())
                .description("Electricity Bill Payment for " + bill.getBillingMonth().format(MONTH_FORMATTER))
                .isSandbox(isSandbox)
                .build();
    }

    @Transactional
    public Payment verifyAndCompletePayment(RazorpayVerificationRequest request, Long userId) {
        Bill bill = billRepository.findById(request.getBillId())
                .orElseThrow(() -> new ResourceNotFoundException("Bill not found with id: " + request.getBillId()));

        if ("PAID".equalsIgnoreCase(bill.getPaymentStatus())) {
            return paymentRepository.findTopByBillOrderByPaymentDateDesc(bill)
                    .orElseThrow(() -> new BadRequestException("Bill is already marked as paid."));
        }

        // Signature verification if live keys & signature provided
        boolean verified = true;
        if (request.getRazorpaySignature() != null && !request.getRazorpaySignature().isBlank()
                && keySecret != null && !keySecret.contains("placeholder")) {
            try {
                JSONObject options = new JSONObject();
                options.put("razorpay_order_id", request.getRazorpayOrderId());
                options.put("razorpay_payment_id", request.getRazorpayPaymentId());
                options.put("razorpay_signature", request.getRazorpaySignature());
                verified = Utils.verifyPaymentSignature(options, keySecret);
            } catch (Exception e) {
                log.warn("Razorpay signature verification exception: {}", e.getMessage());
                verified = false;
            }
        }

        if (!verified) {
            throw new BadRequestException("Razorpay payment signature verification failed.");
        }

        // Save Payment record
        Payment payment = Payment.builder()
                .bill(bill)
                .transactionId(request.getRazorpayPaymentId())
                .paymentMethod("Razorpay")
                .amountPaid(bill.getTotalAmount())
                .status("SUCCESS")
                .build();
        Payment savedPayment = paymentRepository.save(payment);

        // Update Bill
        bill.setPaymentStatus("PAID");
        billRepository.save(bill);

        // Create in-app Notification
        Notification notification = Notification.builder()
                .user(bill.getUser())
                .title("Razorpay Payment Successful")
                .subtitle("₹" + String.format("%.2f", bill.getTotalAmount()) + " paid via Razorpay (Txn: " + request.getRazorpayPaymentId() + ")")
                .type("Payment Success")
                .isRead(false)
                .build();
        notificationRepository.save(notification);

        log.info("Successfully recorded Razorpay payment for Bill #{}, paymentId: {}", bill.getId(), request.getRazorpayPaymentId());
        return savedPayment;
    }
}
