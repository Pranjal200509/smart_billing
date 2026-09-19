package com.billing.repository;

import com.billing.entity.Meter;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface MeterRepository extends JpaRepository<Meter, Long> {
    Optional<Meter> findByMeterNumber(String meterNumber);
    Optional<Meter> findByConsumerNumber(String consumerNumber);
    Optional<Meter> findByUserId(Long userId);
    boolean existsByMeterNumber(String meterNumber);
    boolean existsByConsumerNumber(String consumerNumber);
}
