package com.billing.repository;

import com.billing.entity.MeterReading;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface MeterReadingRepository extends JpaRepository<MeterReading, Long> {
    List<MeterReading> findByMeterIdOrderByReadingDateDesc(Long meterId);
    Optional<MeterReading> findFirstByMeterIdOrderByReadingDateDesc(Long meterId);
}
