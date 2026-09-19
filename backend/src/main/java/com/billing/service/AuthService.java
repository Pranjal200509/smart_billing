package com.billing.service;

import com.billing.dto.*;
import com.billing.entity.Meter;
import com.billing.entity.Role;
import com.billing.entity.User;
import com.billing.exception.BadRequestException;
import com.billing.exception.ResourceNotFoundException;
import com.billing.repository.MeterRepository;
import com.billing.repository.UserRepository;
import com.billing.security.JwtUtils;
import com.billing.security.UserDetailsImpl;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.Map;
import java.util.Random;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class AuthService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private MeterRepository meterRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private AuthenticationManager authenticationManager;

    @Autowired
    private JwtUtils jwtUtils;

    // In-memory mock stores for OTP verification
    private final Map<String, String> otpStore = new ConcurrentHashMap<>();
    private final Map<String, String> resetTokenStore = new ConcurrentHashMap<>();
    private final Random random = new Random();

    @Transactional
    public MessageResponse register(RegisterRequest request) {
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new BadRequestException("Error: Email is already in use!");
        }

        if (userRepository.existsByMobileNumber(request.getMobileNumber())) {
            throw new BadRequestException("Error: Mobile number is already in use!");
        }

        if (meterRepository.existsByMeterNumber(request.getMeterNumber())) {
            throw new BadRequestException("Error: Meter number is already in use!");
        }

        if (meterRepository.existsByConsumerNumber(request.getConsumerNumber())) {
            throw new BadRequestException("Error: Consumer number is already in use!");
        }

        // Generate CUST ID
        String customerId = "CUST" + (100000 + random.nextInt(900000));
        while (userRepository.existsByCustomerId(customerId)) {
            customerId = "CUST" + (100000 + random.nextInt(900000));
        }

        User user = User.builder()
                .customerId(customerId)
                .fullName(request.getFullName())
                .email(request.getEmail())
                .mobileNumber(request.getMobileNumber())
                .password(passwordEncoder.encode(request.getPassword()))
                .address(request.getAddress())
                .city(request.getCity())
                .state(request.getState())
                .pinCode(request.getPinCode())
                .connectionType(request.getConnectionType())
                .loadCapacityKw(5.0)
                .role(Role.ROLE_USER)
                .status("VERIFIED")
                .build();

        User savedUser = userRepository.save(user);

        Meter meter = Meter.builder()
                .meterNumber(request.getMeterNumber())
                .consumerNumber(request.getConsumerNumber())
                .user(savedUser)
                .installationDate(LocalDate.now())
                .currentReadingKwh(0.0)
                .status("ACTIVE")
                .build();

        meterRepository.save(meter);

        return new MessageResponse("User registered successfully! Customer ID: " + customerId);
    }

    public JwtResponse login(LoginRequest request) {
        Authentication authentication = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(request.getEmail(), request.getPassword()));

        SecurityContextHolder.getContext().setAuthentication(authentication);
        String jwt = jwtUtils.generateJwtToken(authentication);

        UserDetailsImpl userDetails = (UserDetailsImpl) authentication.getPrincipal();
        User user = userRepository.findById(userDetails.getId())
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        return new JwtResponse(
                jwt,
                user.getId(),
                user.getFullName(),
                user.getEmail(),
                user.getRole().name(),
                user.getCustomerId()
        );
    }

    public MessageResponse forgotPassword(ForgotPasswordRequest request) {
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new ResourceNotFoundException("No account registered with this email."));

        // Generate 6-digit OTP
        String otp = String.format("%06d", random.nextInt(1000000));
        otpStore.put(request.getEmail(), otp);

        System.out.println("\n--- [SIMULATED OTP DISPATCH] ---");
        System.out.println("To: " + request.getEmail());
        System.out.println("OTP Code: " + otp);
        System.out.println("---------------------------------\n");

        return new MessageResponse("We'll send a 6-digit OTP to your registered email (Simulated in server console).");
    }

    public Map<String, String> verifyOtp(VerifyOtpRequest request) {
        String savedOtp = otpStore.get(request.getEmail());

        if (savedOtp == null || !savedOtp.equals(request.getOtp())) {
            throw new BadRequestException("Invalid OTP Code.");
        }

        // Generate reset token
        String resetToken = UUID.randomUUID().toString();
        resetTokenStore.put(request.getEmail(), resetToken);
        otpStore.remove(request.getEmail()); // Consume OTP

        Map<String, String> response = new ConcurrentHashMap<>();
        response.put("message", "OTP Verified Successfully.");
        response.put("token", resetToken);
        return response;
    }

    @Transactional
    public MessageResponse resetPassword(ResetPasswordRequest request) {
        String savedToken = resetTokenStore.get(request.getEmail());

        if (savedToken == null || !savedToken.equals(request.getToken())) {
            throw new BadRequestException("Invalid or expired reset token.");
        }

        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new ResourceNotFoundException("User not found."));

        user.setPassword(passwordEncoder.encode(request.getNewPassword()));
        userRepository.save(user);

        resetTokenStore.remove(request.getEmail()); // Consume token

        return new MessageResponse("Password has been reset successfully.");
    }
}
