package com.billing.controller;

import com.billing.security.UserDetailsImpl;
import com.billing.service.UsageService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/usage")
public class UsageController {

    @Autowired
    private UsageService usageService;

    @GetMapping("/overview")
    public ResponseEntity<Map<String, Object>> getOverview(@AuthenticationPrincipal UserDetailsImpl userDetails) {
        return ResponseEntity.ok(usageService.getUsageOverview(userDetails.getId()));
    }

    @GetMapping("/chart-data")
    public ResponseEntity<List<Map<String, Object>>> getChartData(@AuthenticationPrincipal UserDetailsImpl userDetails) {
        return ResponseEntity.ok(usageService.getChartData(userDetails.getId()));
    }
}
