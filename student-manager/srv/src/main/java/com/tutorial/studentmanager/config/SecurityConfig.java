package com.tutorial.studentmanager.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.annotation.Order;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.web.SecurityFilterChain;

/**
 * Security configuration to allow unauthenticated access to health endpoints.
 * This is required for SAP BTP Cloud Foundry health checks.
 */
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    /**
     * Security filter chain for actuator endpoints.
     * Order 1 ensures this is evaluated before the default CAP security configuration.
     */
    @Bean
    @Order(1)
    public SecurityFilterChain actuatorSecurityFilterChain(HttpSecurity http) throws Exception {
        http
                .securityMatcher("/actuator/health", "/actuator/health/**", "/actuator/info")
                .authorizeHttpRequests(authorize -> authorize
                        .anyRequest().permitAll()
                );
        return http.build();
    }
}