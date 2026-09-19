package com.billing.repository;

import com.billing.entity.Bill;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface BillRepository extends JpaRepository<Bill, Long> {
    List<Bill> findByUserIdOrderByBillingMonthDesc(Long userId);
    Optional<Bill> findFirstByUserIdOrderByBillingMonthDesc(Long userId);
    Optional<Bill> findFirstByUserIdAndPaymentStatusOrderByBillingMonthDesc(Long userId, String paymentStatus);
    List<Bill> findByPaymentStatus(String paymentStatus);
    boolean existsByUserIdAndBillingMonth(Long userId, LocalDate billingMonth);
}
