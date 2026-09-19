package com.billing.service;

import com.billing.dto.MeterReadingRequest;
import com.billing.entity.*;
import com.billing.exception.BadRequestException;
import com.billing.exception.ResourceNotFoundException;
import com.billing.repository.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.format.TextStyle;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class UsageService {

    @Autowired
    private MeterRepository meterRepository;

    @Autowired
    private MeterReadingRepository meterReadingRepository;

    @Autowired
    private BillRepository billRepository;

    @Transactional
    public void submitReading(MeterReadingRequest request, String recordedBy) {
        Meter meter = meterRepository.findByConsumerNumber(request.getConsumerNumber())
                .orElseThrow(() -> new ResourceNotFoundException("Meter not found with consumer number: " + request.getConsumerNumber()));

        if (request.getReadingValue() < meter.getCurrentReadingKwh()) {
            throw new BadRequestException("New reading (" + request.getReadingValue() + " kWh) cannot be less than the current reading (" + meter.getCurrentReadingKwh() + " kWh).");
        }

        MeterReading reading = MeterReading.builder()
                .meter(meter)
                .readingValue(request.getReadingValue())
                .recordedBy(recordedBy)
                .build();

        meterReadingRepository.save(reading);

        // Update meter current status
        meter.setCurrentReadingKwh(request.getReadingValue());
        meterRepository.save(meter);
    }

    public Map<String, Object> getUsageOverview(Long userId) {
        Meter meter = meterRepository.findByUserId(userId)
                .orElseThrow(() -> new ResourceNotFoundException("Meter not found for user"));

        List<Bill> bills = billRepository.findByUserIdOrderByBillingMonthDesc(userId);

        Double currentReading = meter.getCurrentReadingKwh();
        Double prevReading = 0.0;
        Double unitsUsed = 0.0;
        Double avgUnits = 220.0; // Standard baseline default

        if (!bills.isEmpty()) {
            Bill latestBill = bills.get(0);
            currentReading = latestBill.getCurrentReadingKwh();
            prevReading = latestBill.getPreviousReadingKwh();
            unitsUsed = latestBill.getUnitsConsumed();

            // Calculate historical average based on last 6 bills
            double sum = bills.stream()
                    .limit(6)
                    .mapToDouble(Bill::getUnitsConsumed)
                    .sum();
            avgUnits = sum / Math.min(bills.size(), 6);
        }

        Map<String, Object> overview = new HashMap<>();
        overview.put("currentReadingKwh", currentReading);
        overview.put("previousReadingKwh", prevReading);
        overview.put("unitsUsed", unitsUsed);
        overview.put("averageUnits", Math.round(avgUnits * 100.0) / 100.0);
        return overview;
    }

    public List<Map<String, Object>> getChartData(Long userId) {
        List<Bill> bills = billRepository.findByUserIdOrderByBillingMonthDesc(userId);
        
        // Take last 6 bills, reverse order so they appear chronologically (Jan -> Jun)
        List<Bill> recentBills = bills.stream()
                .limit(6)
                .collect(Collectors.toList());
        Collections.reverse(recentBills);

        List<Map<String, Object>> chartList = new ArrayList<>();
        for (Bill bill : recentBills) {
            Map<String, Object> point = new HashMap<>();
            String monthName = bill.getBillingMonth().getMonth().getDisplayName(TextStyle.SHORT, Locale.ENGLISH);
            point.put("month", monthName);
            point.put("units", bill.getUnitsConsumed());
            chartList.add(point);
        }

        // Return mock baseline data points if no bills have been generated yet
        if (chartList.isEmpty()) {
            String[] months = {"Jan", "Feb", "Mar", "Apr", "May", "Jun"};
            double[] mockUnits = {210, 225, 240, 195, 260, 245};
            for (int i = 0; i < months.length; i++) {
                Map<String, Object> point = new HashMap<>();
                point.put("month", months[i]);
                point.put("units", mockUnits[i]);
                chartList.add(point);
            }
        }

        return chartList;
    }
}
