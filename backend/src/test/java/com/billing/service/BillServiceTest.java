package com.billing.service;

import com.billing.dto.BillDto;
import com.billing.dto.PaymentRequest;
import com.billing.entity.*;
import com.billing.repository.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Mockito;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;

@ExtendWith(MockitoExtension.class)
public class BillServiceTest {

    @Mock
    private BillRepository billRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private MeterRepository meterRepository;

    @Mock
    private MeterReadingRepository meterReadingRepository;

    @Mock
    private PaymentRepository paymentRepository;

    @Mock
    private NotificationRepository notificationRepository;

    @InjectMocks
    private BillService billService;

    private User user;
    private Meter meter;
    private MeterReading reading;

    @BeforeEach
    public void setup() {
        user = User.builder()
                .id(1L)
                .customerId("CUST123456")
                .fullName("Test Customer")
                .email("test@gmail.com")
                .mobileNumber("1234567890")
                .connectionType("Residential")
                .loadCapacityKw(5.0)
                .role(Role.ROLE_USER)
                .build();

        meter = Meter.builder()
                .id(1L)
                .meterNumber("MTR123")
                .consumerNumber("CON123")
                .user(user)
                .currentReadingKwh(100.0)
                .build();

        reading = MeterReading.builder()
                .id(1L)
                .meter(meter)
                .readingValue(350.0) // 350 - 100 = 250 units
                .build();
    }

    @Test
    public void testGenerateBillSuccess() {
        Mockito.when(userRepository.findById(1L)).thenReturn(Optional.of(user));
        Mockito.when(meterRepository.findByUserId(1L)).thenReturn(Optional.of(meter));
        Mockito.when(billRepository.existsByUserIdAndBillingMonth(any(), any())).thenReturn(false);

        ArrayList<MeterReading> readings = new ArrayList<>();
        readings.add(reading);
        Mockito.when(meterReadingRepository.findByMeterIdOrderByReadingDateDesc(1L)).thenReturn(readings);

        Bill savedBill = Bill.builder()
                .id(1L)
                .user(user)
                .billNumber("EB2026050001")
                .billingMonth(LocalDate.of(2026, 5, 1))
                .previousReadingKwh(100.0)
                .currentReadingKwh(350.0)
                .unitsConsumed(250.0)
                .energyCharge(1500.0) // (100 * 4.5) + (150 * 7.0) = 450 + 1050 = 1500
                .fixedCharge(250.0)   // 5 * 50 = 250
                .taxes(150.0)         // 10% of 1500 = 150
                .lateFee(0.0)
                .totalAmount(1900.0)
                .dueDate(LocalDate.now().plusDays(20))
                .paymentStatus("PENDING")
                .build();

        Mockito.when(billRepository.save(any(Bill.class))).thenReturn(savedBill);

        BillDto dto = billService.generateBill(1L, LocalDate.of(2026, 5, 15));

        assertNotNull(dto);
        assertEquals("PENDING", dto.getPaymentStatus());
        assertEquals(250.0, dto.getUnitsConsumed());
        assertEquals(1900.0, dto.getTotalAmount());
        assertEquals(150.0, dto.getTaxes());
    }
}
