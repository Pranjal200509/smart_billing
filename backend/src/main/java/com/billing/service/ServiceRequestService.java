package com.billing.service;

import com.billing.dto.ServiceRequestDto;
import com.billing.entity.ServiceRequest;
import com.billing.entity.User;
import com.billing.exception.ResourceNotFoundException;
import com.billing.repository.ServiceRequestRepository;
import com.billing.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class ServiceRequestService {

    @Autowired
    private ServiceRequestRepository serviceRequestRepository;

    @Autowired
    private UserRepository userRepository;

    @Transactional
    public ServiceRequest submitRequest(Long userId, ServiceRequestDto requestDto) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        long count = serviceRequestRepository.count() + 1001;
        String requestId = "SR" + count;

        ServiceRequest request = ServiceRequest.builder()
                .requestId(requestId)
                .user(user)
                .requestType(requestDto.getRequestType())
                .details(requestDto.getDetails())
                .status("SUBMITTED")
                .build();

        return serviceRequestRepository.save(request);
    }

    public List<ServiceRequest> getRequestsForUser(Long userId) {
        return serviceRequestRepository.findByUserIdOrderByCreatedAtDesc(userId);
    }

    public List<ServiceRequest> getAllRequests() {
        return serviceRequestRepository.findAll();
    }

    @Transactional
    public ServiceRequest updateRequestStatus(Long id, String status) {
        ServiceRequest request = serviceRequestRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Service request not found"));

        request.setStatus(status); // IN_PROGRESS, COMPLETED, REJECTED
        return serviceRequestRepository.save(request);
    }
}
