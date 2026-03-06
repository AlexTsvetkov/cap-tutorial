# Stage 2 – CAP Multitenancy: Complete Implementation Guide

> **Estimated Duration:** 2-3 weeks  
> **Prerequisites:** Stage 1 (CAP Java Basics) completed and deployed  
> **Goal:** Add multitenancy support with schema-per-tenant isolation

---

## Table of Contents

1. [Overview](#1-overview)
2. [Enable Multitenancy in CDS](#2-enable-multitenancy-in-cds)
3. [Update Application Configuration](#3-update-application-configuration)
4. [Update xs-security.json](#4-update-xs-securityjson)
5. [Create Approuter Module](#5-create-approuter-module)
6. [Update MTA for Multitenancy](#6-update-mta-for-multitenancy)
7. [Implement Custom Subscription Handler](#7-implement-custom-subscription-handler)
8. [Build and Deploy](#8-build-and-deploy)
9. [Test Provider Tenant](#9-test-provider-tenant)
10. [Subscribe a Tenant](#10-subscribe-a-tenant)
11. [Test Subscriber Tenant](#11-test-subscriber-tenant)
12. [Troubleshooting](#12-troubleshooting)

---

## 1. Overview

### 1.1 What is Multitenancy?

Multitenancy allows a single application deployment to serve multiple customers (tenants), each with isolated data.

### 1.2 CAP Multitenancy Features

| Feature | Description |
|---------|-------------|
| **Automatic HDI Containers** | Each tenant gets its own HANA schema |
| **Built-in Subscription Callbacks** | CAP handles subscribe/unsubscribe automatically |
| **Tenant-aware Routing** | Tenant resolved from JWT token |
| **MTX Services** | Multitenancy Extension for schema management |

### 1.3 Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Approuter                            │
│   (Routes tenant-specific URLs to backend)                  │
│   tenant-a.app.cfapps... → Backend with tenant-a context    │
└─────────────────────────┬───────────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────────┐
│                    Java Backend (CAP)                       │
│   - Resolves tenant from JWT token                          │
│   - Routes to tenant-specific HDI container                 │
└─────────────────────────┬───────────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────────┐
│                   Service Manager                           │
│   - Provisions HDI containers per tenant                    │
│   - Manages database connections                            │
└─────────────────────────┬───────────────────────────────────┘
                          │
     ┌────────────────────┼────────────────────┐
     ▼                    ▼                    ▼
┌─────────┐        ┌─────────┐         ┌─────────┐
│ HDI     │        │ HDI     │         │ HDI     │
│Provider │        │Tenant A │         │Tenant B │
└─────────┘        └─────────┘         └─────────┘
```

### 1.4 Required Services Changes

| Service | Stage 1 Plan | Stage 2 Plan | Why |
|---------|--------------|--------------|-----|
| XSUAA | application | **broker** | Supports multiple tenants |
| HANA | hdi-shared | (via Service Manager) | Dynamic provisioning |
| Service Manager | N/A | **container** | Creates HDI per tenant |
| SaaS Registry | N/A | **application** | Subscription management |

---

## 2. Enable Multitenancy in CDS

### 2.1 Update Root package.json

Edit `package.json` in root directory:

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
        "@sap/cds-mtxs": "^2",
        "express": "^4"
    },
    "cds": {
        "requires": {
            "db": { "kind": "sql" },
            "multitenancy": true,
            "toggles": true,
            "extensibility": true,
            "[production]": {
                "db": { "kind": "hana" },
                "auth": { "kind": "xsuaa" }
            }
        }
    }
}
```

### 2.2 Install MTX Dependencies

```bash
npm install
```

### 2.3 Configuration Explained

| Property | Purpose |
|----------|---------|
| `@sap/cds-mtxs` | Multitenancy Extension services |
| `multitenancy: true` | Enables tenant isolation |
| `toggles: true` | Feature toggle support |
| `extensibility: true` | Allows tenant-specific extensions |

---

## 3. Update Application Configuration

### 3.1 Update application.yaml

Edit `srv/src/main/resources/application.yaml`:

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
  
  datasource:
    url: jdbc:h2:mem:testdb;DB_CLOSE_DELAY=-1
    driver-class-name: org.h2.Driver
    username: sa
    password:
  
  h2:
    console:
      enabled: true
      path: /h2-console
  
  sql:
    init:
      mode: always
      data-locations: classpath:data.sql

cds:
  odata-v4:
    endpoint:
      path: /odata/v4
  # Multitenancy disabled for local development
  multitenancy:
    enabled: false

management:
  endpoints:
    web:
      exposure:
        include: health,info
  endpoint:
    health:
      show-details: always

# ====================
# CLOUD PROFILE (HANA + MT)
# ====================
---
spring:
  config:
    activate:
      on-profile: cloud
  
  sql:
    init:
      mode: never

cds:
  datasource:
    auto-config:
      enabled: true
  security:
    xsuaa:
      enabled: true
  # Multitenancy enabled in cloud
  multitenancy:
    enabled: true
    mtxs:
      enabled: true
    security:
      # Scope required for subscription callbacks
      subscriptionScope: $XSAPPNAME.mtcallback
```

### 3.2 Configuration Changes Explained

| Property | Value | Purpose |
|----------|-------|---------|
| `cds.multitenancy.enabled` | true | Enables multitenancy |
| `cds.multitenancy.mtxs.enabled` | true | Enables MTX services |
| `cds.multitenancy.security.subscriptionScope` | $XSAPPNAME.mtcallback | Scope for SaaS Registry callbacks |

---

## 4. Update xs-security.json

### 4.1 Key Changes for Multitenancy

Replace `xs-security.json` with:

```json
{
    "xsappname": "student-manager",
    "tenant-mode": "shared",
    "description": "Student Manager - Multitenant OAuth2 Configuration",
    "scopes": [
        {
            "name": "$XSAPPNAME.Read",
            "description": "Read access to Student Manager"
        },
        {
            "name": "$XSAPPNAME.Write",
            "description": "Write access to Student Manager"
        },
        {
            "name": "$XSAPPNAME.mtcallback",
            "description": "Subscription callback scope",
            "grant-as-authority-to-apps": [
                "$XSAPPNAME(application,sap-provisioning,tenant-onboarding)"
            ]
        },
        {
            "name": "$XSAPPNAME.mtdeployment",
            "description": "HDI deployment scope",
            "grant-as-authority-to-apps": [
                "$XSAPPNAME(broker,student-manager)"
            ]
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
    ],
    "authorities": [
        "$XSAPPNAME.mtcallback",
        "$XSAPPNAME.mtdeployment"
    ],
    "oauth2-configuration": {
        "redirect-uris": ["https://*.cfapps.us10-001.hana.ondemand.com/**"],
        "token-validity": 900
    }
}
```

### 4.2 Changes from Stage 1

| Property | Stage 1 | Stage 2 | Why |
|----------|---------|---------|-----|
| `tenant-mode` | dedicated | **shared** | Multiple tenants |
| `mtcallback` scope | N/A | Added | SaaS Registry callbacks |
| `mtdeployment` scope | N/A | Added | HDI deployment |
| `grant-as-authority-to-apps` | N/A | Added | Authorize callback apps |
| `authorities` | N/A | Added | Technical scopes |

### 4.3 Scope Explanation

| Scope | Purpose | Granted To |
|-------|---------|------------|
| `mtcallback` | SaaS Registry subscription/unsubscription | sap-provisioning (SaaS Registry) |
| `mtdeployment` | Deploy database artifacts | broker (our XSUAA) |

---

## 5. Create Approuter Module

### 5.1 Why Approuter?

The Approuter:
- Routes tenant-specific URLs (e.g., `tenant-a.app.cfapps...`)
- Handles authentication (XSUAA)
- Forwards requests to backend with tenant context

### 5.2 Create Approuter Directory

```bash
mkdir -p approuter
```

### 5.3 Create approuter/package.json

```json
{
    "name": "student-manager-approuter",
    "version": "1.0.0",
    "scripts": {
        "start": "node node_modules/@sap/approuter/approuter.js"
    },
    "dependencies": {
        "@sap/approuter": "^16"
    }
}
```

### 5.4 Create approuter/xs-app.json

```json
{
    "welcomeFile": "/odata/v4/StudentService/$metadata",
    "authenticationMethod": "route",
    "sessionTimeout": 30,
    "routes": [
        {
            "source": "^/odata/(.*)$",
            "target": "/odata/$1",
            "destination": "student-manager-srv",
            "authenticationType": "xsuaa",
            "csrfProtection": true
        },
        {
            "source": "^/actuator/(.*)$",
            "target": "/actuator/$1",
            "destination": "student-manager-srv",
            "authenticationType": "none"
        },
        {
            "source": "^/-/cds/(.*)$",
            "target": "/-/cds/$1",
            "destination": "student-manager-srv",
            "authenticationType": "none"
        }
    ]
}
```

### 5.5 Routes Explanation

| Route | Target | Auth | Purpose |
|-------|--------|------|---------|
| `/odata/*` | Backend | XSUAA | OData API (authenticated) |
| `/actuator/*` | Backend | None | Health checks |
| `/-/cds/*` | Backend | None | CAP MTX subscription endpoints |

### 5.6 Install Approuter Dependencies

```bash
cd approuter
npm install
cd ..
```

---

## 6. Update MTA for Multitenancy

### 6.1 Replace mta.yaml

Replace entire `mta.yaml` with:

```yaml
_schema-version: "3.1"
ID: student-manager
version: 1.0.0
description: Student Manager - Multitenant CAP Java Application

parameters:
  enable-parallel-deployments: true

modules:
  # =============================
  # Approuter Module
  # =============================
  - name: student-manager-approuter
    type: approuter.nodejs
    path: approuter
    parameters:
      memory: 256M
      disk-quota: 256M
    properties:
      # CRITICAL: Tenant URL pattern
      # Format: <tenant>-student-manager-approuter.cfapps.<region>.hana.ondemand.com
      TENANT_HOST_PATTERN: "^(.*)-student-manager-approuter.cfapps.us10-001.hana.ondemand.com"
    build-parameters:
      builder: custom
      commands:
        - npm install --production
    provides:
      - name: approuter-url
        properties:
          url: ${default-url}
    requires:
      - name: student-manager-xsuaa
      - name: srv-api
        group: destinations
        properties:
          name: student-manager-srv
          url: ~{srv-url}
          forwardAuthToken: true

  # =============================
  # Java Backend Service
  # =============================
  - name: student-manager-srv
    type: java
    path: srv
    parameters:
      buildpack: sap_java_buildpack_jakarta
      memory: 1024M
    properties:
      SPRING_PROFILES_ACTIVE: cloud
      JBP_CONFIG_COMPONENTS: "jres: ['com.sap.xs.java.buildpack.jre.SAPMachineJRE']"
      JBP_CONFIG_SAP_MACHINE_JRE: '{ version: 21.+ }'
      # Enable MTX services
      CDS_MULTITENANCY_MTXS_ENABLED: true
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
      - name: student-manager-xsuaa
      - name: student-manager-service-manager
      - name: student-manager-saas-registry
      - name: student-manager-destination

  # =============================
  # Database Deployer (Provider Schema)
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
      - name: student-manager-service-manager
        properties:
          hdi-container-name: ${service-name}

# =============================
# Resources (Services)
# =============================
resources:
  # XSUAA - MUST use 'broker' plan for multitenancy
  - name: student-manager-xsuaa
    type: org.cloudfoundry.managed-service
    parameters:
      service: xsuaa
      service-plan: broker
      path: ./xs-security.json

  # Service Manager - Dynamic HDI container provisioning
  - name: student-manager-service-manager
    type: org.cloudfoundry.managed-service
    parameters:
      service: service-manager
      service-plan: container
      service-name: student-manager-service-manager

  # SaaS Registry - Marketplace & subscription management
  - name: student-manager-saas-registry
    type: org.cloudfoundry.managed-service
    parameters:
      service: saas-registry
      service-plan: application
      config:
        xsappname: student-manager
        appName: student-manager
        displayName: "Student Manager"
        description: "Multitenant Student Manager Application"
        category: "Education"
        appUrls:
          # CAP MTX built-in endpoints
          getDependencies: ~{srv-api/srv-url}/-/cds/saas-provisioning/dependencies
          onSubscription: ~{srv-api/srv-url}/-/cds/saas-provisioning/tenant/{tenantId}
          onSubscriptionAsync: true
          onUnSubscriptionAsync: true
          callbackTimeoutMillis: 300000
    requires:
      - name: srv-api

  # Destination Service (optional, for external connections)
  - name: student-manager-destination
    type: org.cloudfoundry.managed-service
    parameters:
      service: destination
      service-plan: lite
```

### 6.2 MTA Changes from Stage 1

| Section | Stage 1 | Stage 2 | Purpose |
|---------|---------|---------|---------|
| Approuter module | N/A | Added | Tenant URL routing |
| XSUAA plan | application | **broker** | Multitenant auth |
| student-manager-db | hdi-shared | Removed | Use Service Manager |
| Service Manager | N/A | Added | Dynamic HDI |
| SaaS Registry | N/A | Added | Subscriptions |
| DB Deployer requires | student-manager-db | **service-manager** | Dynamic HDI |

### 6.3 SaaS Registry Configuration

| Property | Value | Purpose |
|----------|-------|---------|
| `getDependencies` | `/-/cds/saas-provisioning/dependencies` | Service dependencies |
| `onSubscription` | `/-/cds/saas-provisioning/tenant/{tenantId}` | Subscribe/unsubscribe endpoint |
| `onSubscriptionAsync` | true | Async subscription (recommended) |
| `callbackTimeoutMillis` | 300000 | 5 min timeout for HDI creation |

---

## 7. Implement Custom Subscription Handler

### 7.1 Optional: Custom Logic on Subscribe/Unsubscribe

CAP MTX handles subscriptions automatically. Add custom logic only if needed (e.g., seed data).

### 7.2 Create Subscription Handler

Create `srv/src/main/java/com/tutorial/studentmanager/subscription/TenantSubscriptionHandler.java`:

```java
package com.tutorial.studentmanager.subscription;

import com.sap.cds.services.mt.TenantProviderService;
import com.sap.cds.services.handler.EventHandler;
import com.sap.cds.services.handler.annotations.On;
import com.sap.cds.services.handler.annotations.ServiceName;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

/**
 * Custom handler for tenant subscription events.
 * 
 * CAP MTX handles HDI container creation/deletion automatically.
 * This handler adds custom business logic if needed.
 */
@Component
@ServiceName(TenantProviderService.DEFAULT_NAME)
public class TenantSubscriptionHandler implements EventHandler {
    
    private static final Logger log = LoggerFactory.getLogger(TenantSubscriptionHandler.class);

    /**
     * Called when a tenant subscribes to the application.
     * The HDI container is automatically created by CAP MTX before this handler runs.
     */
    @On(event = TenantProviderService.EVENT_SUBSCRIBE)
    public void onSubscribe(TenantProviderService.SubscribeEventContext context) {
        String tenantId = context.getTenant();
        log.info("=== TENANT SUBSCRIPTION STARTED ===");
        log.info("Tenant ID: {}", tenantId);
        
        // Custom initialization logic (optional):
        // - Seed initial data for tenant
        // - Create tenant-specific configurations
        // - Send welcome email
        // - Initialize external integrations
        
        log.info("=== TENANT SUBSCRIPTION COMPLETED ===");
    }

    /**
     * Called when a tenant unsubscribes from the application.
     * The HDI container is automatically deleted by CAP MTX after this handler runs.
     */
    @On(event = TenantProviderService.EVENT_UNSUBSCRIBE)
    public void onUnsubscribe(TenantProviderService.UnsubscribeEventContext context) {
        String tenantId = context.getTenant();
        log.info("=== TENANT UNSUBSCRIPTION STARTED ===");
        log.info("Tenant ID: {}", tenantId);
        
        // Custom cleanup logic (optional):
        // - Archive tenant data
        // - Revoke external integrations
        // - Send farewell email
        // - Clean up external resources
        
        log.info("=== TENANT UNSUBSCRIPTION COMPLETED ===");
    }
}
```

### 7.3 Access Tenant Context in Services

To get the current tenant in your service handlers:

```java
package com.tutorial.studentmanager.handlers;

import com.sap.cds.services.request.RequestContext;
import com.sap.cds.services.runtime.CdsRuntime;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Component
public class StudentServiceHandler implements EventHandler {

    @Autowired
    private CdsRuntime runtime;

    /**
     * Get current tenant ID from request context
     */
    private String getCurrentTenant() {
        return RequestContext.getCurrent(runtime)
            .map(ctx -> ctx.getUserInfo().getTenant())
            .orElse("provider");  // Default to provider if no tenant
    }
    
    @Before(event = CdsService.EVENT_CREATE, entity = Students_.CDS_NAME)
    public void beforeCreate(Students student) {
        String tenant = getCurrentTenant();
        log.info("Creating student in tenant: {}", tenant);
        // tenant-specific logic...
    }
}
```

---

## 8. Build and Deploy

### 8.1 Verify Project Structure

```
student-manager/
├── approuter/                 # NEW: Approuter module
│   ├── package.json
│   └── xs-app.json
├── db/
│   ├── schema.cds
│   └── package.json
├── srv/
│   ├── service.cds
│   ├── pom.xml
│   └── src/main/java/...
├── package.json              # UPDATED: MTX dependencies
├── xs-security.json          # UPDATED: Multitenancy scopes
└── mta.yaml                  # UPDATED: MT modules & services
```

### 8.2 Build MTA Archive

```bash
# Generate HANA artifacts
cds build --for hana

# Build MTA archive
npm run build:mta
```

### 8.3 Delete Old Services (if upgrading from Stage 1)

⚠️ **Important:** Stage 2 uses different services. Delete old services first:

```bash
# Unbind old services
cf unbind-service student-manager-srv student-manager-db
cf unbind-service student-manager-srv student-manager-xsuaa

# Delete old services
cf delete-service student-manager-db -f
cf delete-service student-manager-xsuaa -f

# Delete old app
cf delete student-manager-srv -f
cf delete student-manager-db-deployer -f
```

### 8.4 Deploy to Cloud Foundry

```bash
cf deploy mta_archives/student-manager_1.0.0.mtar
```

### 8.5 Verify Deployment

```bash
# Check all apps
cf apps

# Expected output:
# name                          state   instances
# student-manager-approuter     started 1/1
# student-manager-srv           started 1/1

# Check all services
cf services

# Expected output:
# name                            service          plan
# student-manager-xsuaa           xsuaa            broker
# student-manager-service-manager service-manager  container
# student-manager-saas-registry   saas-registry    application
# student-manager-destination     destination      lite
```

---

## 9. Test Provider Tenant

### 9.1 Get Approuter URL

```bash
cf app student-manager-approuter
```

Note the URL (e.g., `https://your-org-student-manager-approuter.cfapps.us10-001.hana.ondemand.com`)

### 9.2 Get XSUAA Credentials

```bash
cf env student-manager-srv
```

Find in `VCAP_SERVICES.xsuaa[0].credentials`:
- `url` (e.g., `https://your-subdomain.authentication.us10.hana.ondemand.com`)
- `clientid`
- `clientsecret`

### 9.3 Get OAuth Token

```bash
curl -X POST "<xsuaa-url>/oauth/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials&client_id=<clientid>&client_secret=<clientsecret>"
```

### 9.4 Test OData Endpoint

```bash
curl "https://<approuter-url>/odata/v4/StudentService/Students" \
  -H "Authorization: Bearer <token>"
```

**Expected:** Empty array `{"value":[]}` (no data in provider tenant)

---

## 10. Subscribe a Tenant

### 10.1 Option A: Via BTP Cockpit (Consumer Subaccount)

1. **Create a Consumer Subaccount** (if not exists):
   - BTP Cockpit → Account Explorer → Create → Subaccount
   - Name: `consumer-tenant-a`
   - Enable Cloud Foundry

2. **Subscribe to Application:**
   - Go to **Consumer Subaccount** → **Service Marketplace**
   - Find **"Student Manager"** (the name from SaaS Registry)
   - Click **Create** (Subscribe)
   - Wait for subscription to complete (1-5 minutes)

3. **Assign Role Collections:**
   - Consumer Subaccount → **Security** → **Role Collections**
   - Find `StudentManager_Editor`
   - Add your user

### 10.2 Option B: Via CF CLI (Test Subscription)

You can test subscription using the SaaS Registry API:

```bash
# Get SaaS Registry credentials
cf env student-manager-srv | grep -A 50 "saas-registry"

# Make subscription request (simulates BTP subscription)
curl -X PUT "https://<srv-url>/-/cds/saas-provisioning/tenant/<tenant-id>" \
  -H "Authorization: Bearer <saas-registry-token>" \
  -H "Content-Type: application/json" \
  -d '{"subscribedSubdomain": "consumer-a", "subscribedTenantId": "<tenant-guid>"}'
```

### 10.3 Verify Subscription

Check logs during subscription:

```bash
cf logs student-manager-srv --recent | grep -i tenant
```

You should see:
```
=== TENANT SUBSCRIPTION STARTED ===
Tenant ID: <guid>
=== TENANT SUBSCRIPTION COMPLETED ===
```

---

## 11. Test Subscriber Tenant

### 11.1 Map Subscriber Route

After subscription, map a route for the subscriber:

```bash
cf map-route student-manager-approuter cfapps.us10-001.hana.ondemand.com \
  --hostname consumer-a-student-manager-approuter
```

### 11.2 Get Subscriber OAuth Token

Use the **subscriber's XSUAA** (from consumer subaccount):

1. Go to **Consumer Subaccount** → **Service Instances**
2. Find the XSUAA instance (created during subscription)
3. Get credentials (or create a service key)

```bash
# Get token from subscriber's XSUAA
curl -X POST "<subscriber-xsuaa-url>/oauth/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials&client_id=<subscriber-clientid>&client_secret=<subscriber-clientsecret>"
```

### 11.3 Test Subscriber Endpoint

```bash
curl "https://consumer-a-student-manager-approuter.cfapps.us10-001.hana.ondemand.com/odata/v4/StudentService/Students" \
  -H "Authorization: Bearer <subscriber-token>"
```

### 11.4 Test Data Isolation

1. **Create data in Provider tenant:**
```bash
curl -X POST "https://<provider-approuter>/odata/v4/StudentService/Students" \
  -H "Authorization: Bearer <provider-token>" \
  -H "Content-Type: application/json" \
  -d '{"firstName": "Provider", "lastName": "User", "email": "provider@test.com"}'
```

2. **Verify Provider sees the data:**
```bash
curl "https://<provider-approuter>/odata/v4/StudentService/Students" \
  -H "Authorization: Bearer <provider-token>"
# Should return: Provider User
```

3. **Verify Subscriber does NOT see it:**
```bash
curl "https://<subscriber-approuter>/odata/v4/StudentService/Students" \
  -H "Authorization: Bearer <subscriber-token>"
# Should return: empty array (isolated!)
```

4. **Create data in Subscriber tenant:**
```bash
curl -X POST "https://<subscriber-approuter>/odata/v4/StudentService/Students" \
  -H "Authorization: Bearer <subscriber-token>" \
  -H "Content-Type: application/json" \
  -d '{"firstName": "Subscriber", "lastName": "User", "email": "subscriber@test.com"}'
```

5. **Verify isolation both ways:**
```bash
# Provider sees only Provider User
# Subscriber sees only Subscriber User
```

---

## 12. Troubleshooting

### Problem: 403 on Subscription Callback

**Error:**
```
403 Forbidden - Insufficient scope
```

**Cause:** SaaS Registry can't call subscription endpoint.

**Solution:** Verify `xs-security.json` has:
```json
{
  "name": "$XSAPPNAME.mtcallback",
  "grant-as-authority-to-apps": [
    "$XSAPPNAME(application,sap-provisioning,tenant-onboarding)"
  ]
}
```

And `authorities` section:
```json
"authorities": ["$XSAPPNAME.mtcallback", "$XSAPPNAME.mtdeployment"]
```

### Problem: Subscriber Can't Access Application

**Cause:** Route not mapped.

**Solution:**
```bash
cf map-route student-manager-approuter cfapps.us10-001.hana.ondemand.com \
  --hostname <subscriber-subdomain>-student-manager-approuter
```

### Problem: HDI Container Not Created

**Cause:** Service Manager not bound or missing permissions.

**Solution:**
1. Check Service Manager binding:
```bash
cf env student-manager-srv | grep service-manager
```

2. Verify DB deployer uses Service Manager:
```yaml
# In mta.yaml
- name: student-manager-db-deployer
  requires:
    - name: student-manager-service-manager  # NOT student-manager-db!
```

### Problem: Token Invalid for Subscriber

**Cause:** Using provider's XSUAA token for subscriber.

**Solution:** Each tenant has its own XSUAA instance. Get token from the **subscriber's** XSUAA.

### Problem: Subscription Timeout

**Cause:** HDI container creation takes too long.

**Solution:**
1. Increase timeout in SaaS Registry config:
```yaml
callbackTimeoutMillis: 600000  # 10 minutes
```

2. Ensure async subscription is enabled:
```yaml
onSubscriptionAsync: true
```

### Problem: "Service Manager not found"

**Cause:** Missing Service Manager service.

**Solution:**
```bash
cf create-service service-manager container student-manager-service-manager
```

---

## Quick Reference Commands

```bash
# Build and deploy
npm run build:mta
cf deploy mta_archives/student-manager_1.0.0.mtar

# Check apps
cf apps

# Check services
cf services

# View logs
cf logs student-manager-srv --recent

# Map subscriber route
cf map-route student-manager-approuter cfapps.us10-001.hana.ondemand.com \
  --hostname <subscriber>-student-manager-approuter

# Unsubscribe tenant (via API)
curl -X DELETE "https://<srv-url>/-/cds/saas-provisioning/tenant/<tenant-id>" \
  -H "Authorization: Bearer <token>"
```

---

## Checklist

Before moving to Stage 3, verify:

- [ ] Provider tenant can access OData services
- [ ] Application visible in BTP Service Marketplace
- [ ] Subscriber can subscribe via BTP Cockpit
- [ ] Subscriber gets isolated HDI container
- [ ] Subscriber route is mapped and accessible
- [ ] Data is isolated between tenants
- [ ] Custom subscription handler logs appear in logs
- [ ] Unsubscription cleans up HDI container