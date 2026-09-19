package com.billing.repository;

import com.billing.entity.Payment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PaymentRepository extends JpaRepository<Payment, Long> {
    List<Payment> findByBillUserIdOrderByPaymentDateDesc(Long userId);
    java.util.Optional<Payment> findTopByBillOrderByPaymentDateDesc(com.billing.entity.Bill bill);
    boolean existsByTransactionId(String transactionId);
}

