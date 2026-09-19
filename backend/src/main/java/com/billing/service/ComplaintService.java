package com.billing.service;

import com.billing.dto.ComplaintRequest;
import com.billing.entity.Complaint;
import com.billing.entity.User;
import com.billing.exception.ResourceNotFoundException;
import com.billing.repository.ComplaintRepository;
import com.billing.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class ComplaintService {

    @Autowired
    private ComplaintRepository complaintRepository;

    @Autowired
    private UserRepository userRepository;

    @Transactional
    public Complaint submitComplaint(Long userId, ComplaintRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        long count = complaintRepository.count() + 1001;
        String complaintId = "CMP" + count;

        Complaint complaint = Complaint.builder()
                .complaintId(complaintId)
                .user(user)
                .complaintType(request.getComplaintType())
                .description(request.getDescription())
                .status("SUBMITTED")
                .build();

        return complaintRepository.save(complaint);
    }

    public List<Complaint> getComplaintsForUser(Long userId) {
        return complaintRepository.findByUserIdOrderByCreatedAtDesc(userId);
    }

    public List<Complaint> getAllComplaints() {
        return complaintRepository.findAll();
    }

    @Transactional
    public Complaint resolveComplaint(Long id, String resolutionDetails, String status) {
        Complaint complaint = complaintRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Complaint not found"));

        complaint.setResolutionDetails(resolutionDetails);
        complaint.setStatus(status); // RESOLVED, CLOSED
        return complaintRepository.save(complaint);
    }
}
