# Stage 1 – CAP Java Basics: Complete Implementation Guide

> **Estimated Duration:** 1-2 weeks  
> **Prerequisites:** Java 21, Node.js 18+, Maven 3.8+, CF CLI  
> **Goal:** Build and deploy a Student Manager app using SAP CAP Java SDK

---

## Table of Contents

1. [Prerequisites Installation](#1-prerequisites-installation)
2. [Create CAP Java Project](#2-create-cap-java-project)
3. [Define Data Model](#3-define-data-model)
4. [Define Service](#4-define-service)
5. [Implement Custom Handler](#5-implement-custom-handler)
6. [Configure Application](#6-configure-application)
7. [Configure Security](#7-configure-security)
8. [Add Sample Data](#8-add-sample-data)
9. [Run and Test Locally](#9-run-and-test-locally)
10. [Cloud Deployment Setup](#10-cloud-deployment-setup)
11. [Create HANA Cloud Instance](#11-create-hana-cloud-instance)
12. [Build and Deploy to Cloud](#12-build-and-deploy-to-cloud)
13. [Troubleshooting](#13-troubleshooting)

---

## 1. Prerequisites Installation

### 1.1 Install Java 21

Java 21 is **required** for cloud deployment (SAP Java Buildpack supports it).

**macOS (Homebrew):**
```bash
brew install openjdk@21
```

**Verify:**
```bash
java -version
# Should show: openjdk version "21.x.x"
```

### 1.2 Install Node.js 18+

Required for CDS build tools.

```bash
brew install node@18
```

**Verify:**
```bash
node -v
# Should show: v18.x.x or higher
```

### 1.3 Install CDS Development Kit

```bash
npm install -g @sap/cds-dk
```

**Verify:**
```bash
cds version
```

### 1.4 Install MTA Build Tool

```bash
npm install -g mbt
```

**Verify:**
```bash
mbt --version
```

### 1.5 Install Cloud Foundry CLI

**macOS (Homebrew):**
```bash
brew install cloudfoundry/tap/cf-cli@8
```

### 1.6 Install CF Multiapps Plugin

Required for MTA deployment:

```bash
cf install-plugin multiapps
```

**Verify all installations:**
```bash
cds version
mbt --version
cf version
cf plugins | grep multiapps
java -version
node -v
mvn -v
```

---

## 2. Create CAP Java Project

### 2.1 Scaffold Project Using Maven Archetype

Run this command in your workspace directory:

```bash
mvn archetype:generate \
  -DarchetypeGroupId=com.sap.cds \
  -DarchetypeArtifactId=cds-services-archetype \
  -DarchetypeVersion=RELEASE \
  -DgroupId=com.tutorial \
  -DartifactId=student-manager \
  -Dversion=1.0.0 \
  -Dpackage=com.tutorial.studentmanager \
  -DinteractiveMode=false
```

### 2.2 Navigate to Project and Install Dependencies

```bash
cd student-manager
npm install
```

### 2.3 Project Structure

After scaffolding, you'll have:

```
student-manager/
├── db/                    # Database module (CDS models)
│   └── package.json
├── srv/                   # Service module (Java backend)
│   ├── pom.xml
│   └── src/
│       ├── gen/           # Generated Java classes (from CDS)
│       └── main/
│           ├── java/      # Your Java code
│           └── resources/ # Configuration files
├── package.json           # Root npm configuration
└── pom.xml               # Root Maven POM
```

---

## 3. Define Data Model

### 3.1 Create Schema File

Create file `db/schema.cds`:

```cds
namespace tutorial;
using { cuid, managed } from '@sap/cds/common';

/**
 * Student entity with automatic UUID and audit fields
 * - cuid: Adds 'ID' field (UUID, auto-generated)
 * - managed: Adds createdAt, createdBy, modifiedAt, modifiedBy
 */
entity Students : cuid, managed {
    firstName    : String(100) @mandatory;
    lastName     : String(100) @mandatory;
    email        : String(255) @mandatory;
    dateOfBirth  : Date;
    status       : String(20) default 'ACTIVE';
}
```

### 3.2 Understanding CDS Aspects

| Aspect | Fields Added | Description |
|--------|-------------|-------------|
| `cuid` | `ID: UUID` | Auto-generated primary key |
| `managed` | `createdAt`, `createdBy`, `modifiedAt`, `modifiedBy` | Audit fields, auto-populated |

---

## 4. Define Service

### 4.1 Create Service File

Create file `srv/service.cds`:

```cds
using { tutorial } from '../db/schema';

/**
 * StudentService - OData V4 service exposing Students entity
 * CAP automatically provides CRUD operations (generic handlers)
 */
service StudentService {
    entity Students as projection on tutorial.Students;
}
```

### 4.2 What CAP Provides Automatically

With just this service definition, CAP provides:

| Operation | HTTP Method | Endpoint |
|-----------|-------------|----------|
| Read all | GET | `/odata/v4/StudentService/Students` |
| Read one | GET | `/odata/v4/StudentService/Students({id})` |
| Create | POST | `/odata/v4/StudentService/Students` |
| Update | PATCH | `/odata/v4/StudentService/Students({id})` |
| Delete | DELETE | `/odata/v4/StudentService/Students({id})` |
| Metadata | GET | `/odata/v4/StudentService/$metadata` |

---

## 5. Implement Custom Handler

### 5.1 Generate Java Classes from CDS

First, compile to generate Java entities:

```bash
cd srv
mvn compile
```

This generates Java classes in `srv/src/gen/java/`:
- `cds/gen/studentservice/Students.java`
- `cds/gen/studentservice/Students_.java` (metadata)
- `cds/gen/studentservice/StudentService_.java`

### 5.2 Create Custom Handler

Create file `srv/src/main/java/com/tutorial/studentmanager/handlers/StudentServiceHandler.java`:

```java
package com.tutorial.studentmanager.handlers;

import com.sap.cds.services.cds.CdsService;
import com.sap.cds.services.handler.EventHandler;
import com.sap.cds.services.handler.annotations.Before;
import com.sap.cds.services.handler.annotations.ServiceName;
import com.sap.cds.services.ErrorStatuses;
import com.sap.cds.services.ServiceException;

import cds.gen.studentservice.Students;
import cds.gen.studentservice.Students_;

import org.springframework.stereotype.Component;

/**
 * Custom event handler for StudentService
 * 
 * CAP provides generic CRUD operations automatically.
 * Use handlers to add custom business logic:
 * - @Before: Execute before the default operation
 * - @After: Execute after the default operation
 * - @On: Replace the default operation
 */
@Component
@ServiceName("StudentService")
public class StudentServiceHandler implements EventHandler {

    /**
     * Validates email format before CREATE and UPDATE operations
     * 
     * @param student The student entity being created/updated
     * @throws ServiceException if email is invalid
     */
    @Before(event = {CdsService.EVENT_CREATE, CdsService.EVENT_UPDATE}, entity = Students_.CDS_NAME)
    public void validateEmail(Students student) {
        String email = student.getEmail();
        
        if (email != null && !email.contains("@")) {
            throw new ServiceException(ErrorStatuses.BAD_REQUEST,
                "Invalid email format: " + email + ". Email must contain '@' character.");
        }
    }
}
```

### 5.3 Handler Annotations Explained

| Annotation | When | Use Case |
|------------|------|----------|
| `@Before` | Before generic handler | Validation, preprocessing |
| `@After` | After generic handler | Postprocessing, enrichment |
| `@On` | Instead of generic handler | Custom implementation |

---

## 6. Configure Application

### 6.1 Create Application Configuration

Create file `srv/src/main/resources/application.yaml`:

```yaml
spring:
  application:
    name: student-manager
  profiles:
    active: default

# ====================
# LOCAL PROFILE (H2)
# ====================
---
spring:
  config:
    activate:
      on-profile: default
  
  # H2 In-Memory Database
  datasource:
    url: jdbc:h2:mem:testdb;DB_CLOSE_DELAY=-1
    driver-class-name: org.h2.Driver
    username: sa
    password:
  
  # H2 Console (accessible at /h2-console)
  h2:
    console:
      enabled: true
      path: /h2-console
  
  # Load sample data on startup
  sql:
    init:
      mode: always
      data-locations: classpath:data.sql

# CDS Configuration
cds:
  odata-v4:
    endpoint:
      path: /odata/v4

# Actuator endpoints for health checks
management:
  endpoints:
    web:
      exposure:
        include: health,info
  endpoint:
    health:
      show-details: always

# ====================
# CLOUD PROFILE (HANA)
# ====================
---
spring:
  config:
    activate:
      on-profile: cloud
  
  # Disable local data loading in cloud
  sql:
    init:
      mode: never

# Cloud CDS Configuration
cds:
  datasource:
    auto-config:
      enabled: true
  security:
    xsuaa:
      enabled: true
```

### 6.2 Configuration Explanation

| Section | Purpose |
|---------|---------|
| `spring.profiles.active` | Sets default profile for local development |
| `spring.datasource` | H2 database configuration for local |
| `spring.h2.console` | Enables H2 web console |
| `spring.sql.init` | Loads sample data on startup |
| `cds.odata-v4` | OData endpoint path configuration |
| `cds.security.xsuaa` | Enables XSUAA security in cloud |

---

## 7. Configure Security

### 7.1 Create Security Configuration

Create file `srv/src/main/java/com/tutorial/studentmanager/config/SecurityConfig.java`:

```java
package com.tutorial.studentmanager.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;
import org.springframework.core.annotation.Order;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.provisioning.InMemoryUserDetailsManager;
import org.springframework.security.web.SecurityFilterChain;

/**
 * Spring Security Configuration
 * 
 * Provides dual security setup:
 * - Local (default profile): Basic Auth with mock users
 * - Cloud (cloud profile): XSUAA OAuth2 (handled by CAP)
 */
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    /**
     * Actuator endpoints - NO authentication required
     * Must be Order(1) to be evaluated first
     * 
     * This is REQUIRED for BTP health checks!
     */
    @Bean
    @Order(1)
    public SecurityFilterChain actuatorSecurityFilterChain(HttpSecurity http) throws Exception {
        http
            .securityMatcher("/actuator/**")
            .authorizeHttpRequests(auth -> auth.anyRequest().permitAll());
        return http.build();
    }

    /**
     * Local profile security - Basic Auth
     * Only active when spring.profiles.active=default
     */
    @Bean
    @Order(2)
    @Profile("default")
    public SecurityFilterChain defaultSecurityFilterChain(HttpSecurity http) throws Exception {
        http
            .csrf(csrf -> csrf.disable())
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/h2-console/**").permitAll()  // H2 Console access
                .anyRequest().authenticated())                   // All else requires auth
            .headers(headers -> headers
                .frameOptions(frame -> frame.disable()))         // Allow H2 console iframe
            .httpBasic(basic -> {});                             // Enable Basic Auth
        
        return http.build();
    }

    /**
     * Mock users for local development
     * Only active when spring.profiles.active=default
     */
    @Bean
    @Profile("default")
    public UserDetailsService users() {
        return new InMemoryUserDetailsManager(
            User.withDefaultPasswordEncoder()
                .username("admin")
                .password("admin")
                .roles("ADMIN", "USER")
                .build(),
            User.withDefaultPasswordEncoder()
                .username("user")
                .password("user")
                .roles("USER")
                .build()
        );
    }
}
```

### 7.2 Security Configuration Explained

| Bean | Profile | Purpose |
|------|---------|---------|
| `actuatorSecurityFilterChain` | All | Public health endpoints for BTP |
| `defaultSecurityFilterChain` | default | Basic Auth for local testing |
| `users()` | default | Mock users (admin/admin, user/user) |

**In cloud**, CAP's XSUAA integration handles security automatically via `cds.security.xsuaa.enabled: true`.

---

## 8. Add Sample Data

### 8.1 Create Sample Data SQL

Create file `srv/src/main/resources/data.sql`:

```sql
-- Sample data for local development (H2 database)
-- This file is loaded when spring.sql.init.mode=always (default profile)
-- 
-- NOTE: Table name follows CDS convention: namespace_EntityName
-- tutorial.Students -> tutorial_Students

INSERT INTO tutorial_Students (ID, firstName, lastName, email, dateOfBirth, status)
VALUES 
    ('11111111-1111-1111-1111-111111111111', 'Alice', 'Johnson', 'alice@example.com', '2000-05-14', 'ACTIVE'),
    ('22222222-2222-2222-2222-222222222222', 'Bob', 'Smith', 'bob@example.com', '1999-11-30', 'ACTIVE'),
    ('33333333-3333-3333-3333-333333333333', 'Carol', 'Williams', 'carol@example.com', '2001-02-20', 'INACTIVE');
```

### 8.2 CDS to Database Table Naming

| CDS Definition | Database Table Name |
|---------------|---------------------|
| `tutorial.Students` | `tutorial_Students` |
| `myapp.Orders` | `myapp_Orders` |
| `com.example.Products` | `com_example_Products` |

---

## 9. Run and Test Locally

### 9.1 Build and Run

```bash
cd srv
mvn clean compile
mvn spring-boot:run
```

### 9.2 Test Endpoints

**OData Metadata:**
```bash
curl http://localhost:8080/odata/v4/StudentService/\$metadata \
  -u admin:admin
```

**Get All Students:**
```bash
curl http://localhost:8080/odata/v4/StudentService/Students \
  -u admin:admin
```

**Get Single Student:**
```bash
curl http://localhost:8080/odata/v4/StudentService/Students\(11111111-1111-1111-1111-111111111111\) \
  -u admin:admin
```

**Create Student:**
```bash
curl -X POST http://localhost:8080/odata/v4/StudentService/Students \
  -H "Content-Type: application/json" \
  -u admin:admin \
  -d '{
    "firstName": "David",
    "lastName": "Brown",
    "email": "david@example.com",
    "dateOfBirth": "1998-03-25",
    "status": "ACTIVE"
  }'
```

**Test Email Validation (should fail):**
```bash
curl -X POST http://localhost:8080/odata/v4/StudentService/Students \
  -H "Content-Type: application/json" \
  -u admin:admin \
  -d '{
    "firstName": "Invalid",
    "lastName": "Email",
    "email": "not-an-email"
  }'
```

**Health Check (no auth required):**
```bash
curl http://localhost:8080/actuator/health
```

**H2 Console:**
Open browser: http://localhost:8080/h2-console
- JDBC URL: `jdbc:h2:mem:testdb`
- Username: `sa`
- Password: (empty)

---

## 10. Cloud Deployment Setup

### 10.1 Add Cloud Dependencies

Edit `srv/pom.xml` and add these dependencies:

```xml
<!-- Add inside <dependencies> section -->

<!-- HANA Database Support -->
<dependency>
    <groupId>com.sap.cds</groupId>
    <artifactId>cds-feature-hana</artifactId>
    <scope>runtime</scope>
</dependency>

<!-- Cloud Foundry Integration -->
<dependency>
    <groupId>com.sap.cds</groupId>
    <artifactId>cds-starter-cloudfoundry</artifactId>
</dependency>

<!-- Spring Boot Actuator (health checks) -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
```

### 10.2 Configure Root package.json

Edit `package.json` (root directory):

```json
{
    "name": "student-manager",
    "version": "1.0.0",
    "scripts": {
        "build:mta": "cds build --for hana && mbt build -t mta_archives/",
        "build:hana": "cds build --for hana",
        "deploy": "cf deploy mta_archives/student-manager_1.0.0.mtar"
    },
    "dependencies": {
        "@sap/cds": "^8",
        "express": "^4"
    },
    "cds": {
        "requires": {
            "db": { "kind": "sql" },
            "[production]": {
                "db": { "kind": "hana" },
                "auth": { "kind": "xsuaa" }
            }
        }
    }
}
```

### 10.3 Configure db/package.json

**⚠️ CRITICAL:** Must include `hdb` dependency!

Edit `db/package.json`:

```json
{
    "name": "student-manager-db",
    "dependencies": {
        "@sap/hdi-deploy": "^5",
        "hdb": "^0.19.0"
    },
    "scripts": {
        "start": "node node_modules/@sap/hdi-deploy/deploy.js"
    }
}
```

Run `npm install` in db folder:

```bash
cd db
npm install
cd ..
```

### 10.4 Create xs-security.json

Create file `xs-security.json` in root directory:

```json
{
    "xsappname": "student-manager",
    "tenant-mode": "dedicated",
    "description": "Student Manager OAuth2 Configuration",
    "scopes": [
        {
            "name": "$XSAPPNAME.Read",
            "description": "Read access to Student Manager"
        },
        {
            "name": "$XSAPPNAME.Write",
            "description": "Write access to Student Manager"
        }
    ],
    "role-templates": [
        {
            "name": "Viewer",
            "description": "View student data",
            "scope-references": ["$XSAPPNAME.Read"]
        },
        {
            "name": "Editor",
            "description": "Edit student data",
            "scope-references": ["$XSAPPNAME.Read", "$XSAPPNAME.Write"]
        }
    ],
    "role-collections": [
        {
            "name": "StudentManager_Viewer",
            "description": "View-only access",
            "role-template-references": ["$XSAPPNAME.Viewer"]
        },
        {
            "name": "StudentManager_Editor",
            "description": "Full access",
            "role-template-references": ["$XSAPPNAME.Editor"]
        }
    ]
}
```

### 10.5 Create mta.yaml

Create file `mta.yaml` in root directory:

```yaml
_schema-version: "3.1"
ID: student-manager
version: 1.0.0
description: Student Manager - CAP Java Application

modules:
  # =============================
  # Java Backend Service Module
  # =============================
  - name: student-manager-srv
    type: java
    path: srv
    parameters:
      buildpack: sap_java_buildpack_jakarta
      memory: 1024M
    properties:
      SPRING_PROFILES_ACTIVE: cloud
      # CRITICAL: Specify Java 21 runtime
      JBP_CONFIG_COMPONENTS: "jres: ['com.sap.xs.java.buildpack.jre.SAPMachineJRE']"
      JBP_CONFIG_SAP_MACHINE_JRE: '{ version: 21.+ }'
    build-parameters:
      builder: custom
      commands:
        - mvn clean package -DskipTests
      build-result: target/*-exec.jar
    provides:
      - name: srv-api
        properties:
          srv-url: ${default-url}
    requires:
      - name: student-manager-db
      - name: student-manager-xsuaa

  # =============================
  # Database Deployer Module
  # =============================
  - name: student-manager-db-deployer
    type: hdb
    path: db
    parameters:
      buildpack: nodejs_buildpack
    build-parameters:
      builder: custom
      commands:
        - npm install --production
    requires:
      - name: student-manager-db

# =============================
# Resources (Services)
# =============================
resources:
  # HANA HDI Container
  - name: student-manager-db
    type: com.sap.xs.hdi-container
    parameters:
      service: hana
      service-plan: hdi-shared

  # XSUAA Authentication
  - name: student-manager-xsuaa
    type: org.cloudfoundry.managed-service
    parameters:
      service: xsuaa
      service-plan: application
      path: ./xs-security.json
```

### 10.6 MTA Configuration Explained

| Section | Purpose |
|---------|---------|
| `modules[0]` | Java backend service configuration |
| `JBP_CONFIG_SAP_MACHINE_JRE` | **CRITICAL:** Sets Java 21 runtime |
| `build-parameters.commands` | Maven build command |
| `modules[1]` | HDI deployer for database artifacts |
| `resources[0]` | HANA HDI container service |
| `resources[1]` | XSUAA authentication service |

---

## 11. Create HANA Cloud Instance

**⚠️ CRITICAL:** You must create a HANA Cloud instance BEFORE deploying!

### 11.1 Option A: Via BTP Cockpit (Recommended for First Time)

1. Go to [SAP BTP Cockpit](https://cockpit.hanatrial.ondemand.com/)
2. Navigate to your **Subaccount** → **Service Marketplace**
3. Search for **"SAP HANA Cloud"**
4. Click **Create**
5. Select plan: **`hana-free`** (for trial accounts)
6. Configure:
   - **Instance Name:** `student-manager-hana`
   - **Administrator Password:** Set a secure password
   - **Allowed Connections:** "Allow all IP addresses" (for trial)
7. Click **Create**
8. **Wait 10-20 minutes** for "Running" status

### 11.2 Option B: Via CF CLI

Create file `hana-cloud-config.json`:

```json
{
    "data": {
        "memory": 16,
        "systempassword": "YourSecurePassword123!",
        "edition": "cloud",
        "whitelistIPs": ["0.0.0.0/0"]
    }
}
```

Run:
```bash
cf create-service hana-cloud hana-free student-manager-hana -c hana-cloud-config.json
```

### 11.3 Verify HANA Cloud Status

```bash
cf service student-manager-hana
```

Wait until status shows "create succeeded" and instance is "Running".

---

## 12. Build and Deploy to Cloud

### 12.1 Login to Cloud Foundry

```bash
# Get API endpoint from BTP Cockpit > Subaccount > Overview
cf login -a https://api.cf.us10-001.hana.ondemand.com

# Or use SSO
cf login -a https://api.cf.us10-001.hana.ondemand.com --sso
```

### 12.2 Build MTA Archive

**⚠️ CRITICAL:** Must run `cds build --for hana` to generate database artifacts!

```bash
# Option A: Use npm script (recommended)
npm run build:mta

# Option B: Manual commands
cds build --for hana    # Generate HANA table/view definitions
mbt build               # Build MTA archive
```

### 12.3 Understanding CDS Build

| Command | Output | Purpose |
|---------|--------|---------|
| `cds build --for java` | `srv/src/gen/` | Java classes, OData metadata |
| `cds build --for hana` | `db/src/gen/` | `.hdbtable`, `.hdbview` files |

**Why both are needed:**
- `mvn compile` only runs `cds build --for java`
- HANA needs `.hdbtable` files from `cds build --for hana`
- Without HANA artifacts → "Table not found" errors

### 12.4 Deploy to Cloud Foundry

```bash
# Deploy MTA archive
cf deploy mta_archives/student-manager_1.0.0.mtar

# Or use npm script
npm run deploy
```

### 12.5 Verify Deployment

```bash
# Check apps
cf apps

# Check services
cf services

# View logs
cf logs student-manager-srv --recent

# Get app URL
cf app student-manager-srv
```

### 12.6 Test Cloud Endpoints

For cloud testing, you need an OAuth2 token:

1. Get XSUAA credentials:
   ```bash
   cf env student-manager-srv
   ```

2. Find in `VCAP_SERVICES.xsuaa[0].credentials`:
   - `url` (token URL)
   - `clientid`
   - `clientsecret`

3. Get token:
   ```bash
   curl -X POST <url>/oauth/token \
     -H "Content-Type: application/x-www-form-urlencoded" \
     -d "grant_type=client_credentials&client_id=<clientid>&client_secret=<clientsecret>"
   ```

4. Use token in requests:
   ```bash
   curl https://<app-url>/odata/v4/StudentService/Students \
     -H "Authorization: Bearer <token>"
   ```

---

## 13. Troubleshooting

### Problem: "Table TUTORIAL_STUDENTS not found" (500 Error)

**Cause:** HANA database artifacts (`.hdbtable` files) were not deployed.

**Solution:**
```bash
# Generate HANA artifacts
cds build --for hana

# Rebuild and redeploy
npm run build:mta
cf deploy mta_archives/student-manager_1.0.0.mtar
```

### Problem: "Could not create service student-manager-db"

**Cause:** No HANA Cloud instance exists.

**Solution:**
1. Create HANA Cloud instance (see Step 11)
2. Wait for "Running" status
3. Retry deployment

### Problem: "UnsupportedClassVersionError" (Java version mismatch)

**Cause:** Code compiled with Java 21, but runtime using Java 17.

**Error:**
```
UnsupportedClassVersionError: class file version 65.0 vs 61.0
```

**Solution:** Ensure `mta.yaml` has:
```yaml
properties:
  JBP_CONFIG_SAP_MACHINE_JRE: '{ version: 21.+ }'
```

### Problem: "requires hdb peer dependency"

**Cause:** Missing `hdb` in `db/package.json`.

**Solution:**
```bash
# Add to db/package.json
"dependencies": {
    "@sap/hdi-deploy": "^5",
    "hdb": "^0.19.0"
}

# Install and rebuild
cd db && npm install && cd ..
npm run build:mta
cf deploy mta_archives/student-manager_1.0.0.mtar
```

### Problem: "HANA Database instance is stopped"

**Cause:** Trial HANA instances auto-stop after inactivity.

**Solution:**
1. Go to BTP Cockpit → SAP HANA Cloud Central
2. Find your instance
3. Click ⋮ menu → **Start**
4. Wait 2-5 minutes
5. Retry deployment

---

## Quick Reference Commands

```bash
# Local development
cd srv && mvn spring-boot:run

# Build for cloud
npm run build:mta

# Deploy to cloud
npm run deploy

# View logs
cf logs student-manager-srv --recent

# Restart app
cf restart student-manager-srv

# Check services
cf services
```

---

## Checklist

Before moving to Stage 2, verify:

- [ ] Local app runs with `mvn spring-boot:run`
- [ ] Can access OData endpoint locally with Basic Auth
- [ ] Email validation works (rejects emails without @)
- [ ] Health endpoint accessible without auth
- [ ] HANA Cloud instance is "Running"
- [ ] MTA deployed successfully
- [ ] Cloud app returns data via OAuth2 token
- [ ] All 3 sample students visible in cloud