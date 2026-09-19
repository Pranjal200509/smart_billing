package com.billing.repository;

import com.billing.entity.ServiceRequest;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ServiceRequestRepository extends JpaRepository<ServiceRequest, Long> {
    List<ServiceRequest> findByUserIdOrderByCreatedAtDesc(Long userId);
    boolean existsByRequestId(String requestId);
}
