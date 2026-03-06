# CAP Java Student Manager - Step-by-Step Implementation

This guide walks through creating a CAP Java application from scratch and deploying it to SAP BTP Cloud Foundry.

## Step 1 - Prerequisites & Tool Installation

Required tools:
- Node.js (≥18): `node -v`
- Java JDK 21: `java -version` (required for cloud deployment)
- Maven (3.8+): `mvn -version`
- @sap/cds-dk: `cds version`
- Cloud Foundry CLI: `cf version`
- MBT (MTA Build Tool): `mbt --version`

Install commands:
```bash
npm install -g @sap/cds-dk
npm install -g mbt
brew install cloudfoundry/tap/cf-cli@8
cf install-plugin multiapps
```

## Step 2 - Create GitHub Repository & Clone

1. Create repo on GitHub: `cap-tutorial`
2. Clone: `git clone git@github.com:YOUR_USERNAME/cap-tutorial.git`
3. Update `.gitignore` for CAP Java:
```gitignore
# Node
node_modules/

# Java
target/
*.class
*.jar

# CAP generated
db/src/gen/
srv/src/gen/

# MTA
mta_archives/
*.mtar

# IDE
.idea/
*.iml
.vscode/
```

## Step 3 - Scaffold CAP Java Project with Maven

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

cd student-manager
npm install
```

Generated structure:
- `pom.xml` - Parent POM (multi-module)
- `package.json` - Node.js dependencies for CDS
- `srv/` - Java service module
- `db/` - Database module

## Step 4 - Understand Project Structure & pom.xml

Key dependencies in `srv/pom.xml`:
- `cds-starter-spring-boot` - CAP Java SDK starter
- `cds-adapter-odata-v4` - OData V4 adapter
- `h2` - In-memory database for local dev

CDS Maven Plugin generates:
- Java interfaces from CDS models
- CSN (Core Schema Notation)
- OData EDMX metadata

---

## Step 5 - Data Model

Create `db/schema.cds`:

```cds
namespace tutorial;
using { cuid, managed } from '@sap/cds/common';

entity Students : cuid, managed {
    firstName    : String(100) @mandatory;
    lastName     : String(100) @mandatory;
    email        : String(255) @mandatory;
    dateOfBirth  : Date;
    status       : String(20) default 'ACTIVE';
}
```

---

## Step 6 - Service Definition

Create `srv/service.cds`:

```cds
using { tutorial } from '../db/schema';

service StudentService {
    entity Students as projection on tutorial.Students;
}
```

---

## Step 6.1 - Generate Java Classes from CDS Models

After defining the data model and service, you must generate the Java interfaces before writing handlers.

```bash
cd student-manager
mvn clean compile
```

This command triggers the CDS Maven Plugin (`cds-maven-plugin`) which:
1. Compiles CDS models (`db/schema.cds`, `srv/service.cds`)
2. Generates Java interfaces in `srv/src/gen/java/cds/gen/`

### Generated Files

After running `mvn compile`, you'll find:

**`srv/src/gen/java/cds/gen/studentservice/`**:
- `Students.java` - Entity interface with getters/setters
- `Students_.java` - Static metadata class with `CDS_NAME` constant
- `StudentService_.java` - Service metadata

**`srv/src/gen/java/cds/gen/tutorial/`**:
- `Students.java` - Base entity from `db/schema.cds`

These generated classes are required for:
- Type-safe entity access in handlers
- Event handler annotations (e.g., `@Before(entity = Students_.CDS_NAME)`)
- Compile-time validation of entity names

⚠️ **Important**: Always regenerate after modifying `.cds` files:
```bash
mvn clean compile
```

---

## Step 7 - Java Handler (Optional Email Validation)

Create `srv/src/main/java/com/tutorial/studentmanager/handlers/StudentServiceHandler.java`:

```java
package com.tutorial.studentmanager.handlers;

import cds.gen.studentservice.Students;
import cds.gen.studentservice.Students_;
import com.sap.cds.services.cds.CqnService;
import com.sap.cds.services.handler.EventHandler;
import com.sap.cds.services.handler.annotations.Before;
import com.sap.cds.services.handler.annotations.ServiceName;
import org.springframework.stereotype.Component;

@Component
@ServiceName("StudentService")
public class StudentServiceHandler implements EventHandler {

    @Before(event = {CqnService.EVENT_CREATE, CqnService.EVENT_UPDATE}, entity = Students_.CDS_NAME)
    public void validateEmail(Students student) {
        String email = student.getEmail();
        if (email != null && !email.contains("@")) {
            throw new com.sap.cds.services.ServiceException(
                    com.sap.cds.services.ErrorStatuses.BAD_REQUEST,
                    "Invalid email format: " + email + ". Email must contain '@' character."
            );
        }
    }
}
```

---

## Step 8 - Sample Data (Local Development Only)

Create `srv/src/main/resources/data.sql`:

```sql
INSERT INTO tutorial_Students (ID, firstName, lastName, email, dateOfBirth, status)
VALUES 
    ('11111111-1111-1111-1111-111111111111', 'Alice', 'Johnson', 'alice@example.com', '2000-05-14', 'ACTIVE'),
    ('22222222-2222-2222-2222-222222222222', 'Bob', 'Smith', 'bob@example.com', '1999-11-30', 'ACTIVE'),
    ('33333333-3333-3333-3333-333333333333', 'Carol', 'Williams', 'carol@example.com', '2001-02-20', 'INACTIVE');
```

---

## Step 9 - Application Configuration

**Before this step**, you may have a minimal `application.yaml` like this:

```yaml
spring:
  config.activate.on-profile: default
  sql.init.platform: h2
cds:
  data-source.auto-config.enabled: false
```

**Replace it** with the full configuration below. The file uses **multi-document YAML** (`---` separators) to define settings for different environments in a single file.

---

### Configuration Structure Overview

The `application.yaml` is divided into three sections:

| Section | Activates When | Purpose |
|---------|----------------|---------|
| **Common** (top) | Always | Shared settings for all profiles |
| **default** profile | Local dev (`mvn spring-boot:run`) | H2 database, mock auth |
| **cloud** profile | SAP BTP deployment | HANA auto-detection, XSUAA OAuth2 |

---

### Section 1: Common Configuration (All Profiles)

```yaml
spring:
  application:
    name: student-manager

cds:
  odata-v4:
    endpoint:
      path: /odata/v4

management:
  endpoints:
    web:
      exposure:
        include: health,info
  endpoint:
    health:
      show-details: when-authorized

logging:
  level:
    com.sap.cds: INFO
    com.tutorial: DEBUG
```

| Property | Purpose |
|----------|---------|
| `spring.application.name` | Identifies app in logs, monitoring, and Cloud Foundry |
| `cds.odata-v4.endpoint.path` | Base path for OData services → `/odata/v4/StudentService` |
| `management.endpoints.web.exposure.include` | Exposes `/actuator/health` and `/actuator/info` for health checks |
| `management.endpoint.health.show-details` | Shows health details only to authenticated users |
| `logging.level` | Sets log verbosity (DEBUG for our code, INFO for CAP SDK) |

---

### Section 2: LOCAL Profile (`default`)

```yaml
---
spring:
  config:
    activate:
      on-profile: default
  datasource:
    url: jdbc:h2:mem:studentdb;DB_CLOSE_DELAY=-1;CASE_INSENSITIVE_IDENTIFIERS=TRUE
    driver-class-name: org.h2.Driver
  sql:
    init:
      mode: always
      schema-locations: classpath:schema-h2.sql
      continue-on-error: false
  h2:
    console:
      enabled: true

cds:
  datasource:
    auto-config:
      enabled: true
  security:
    mock:
      enabled: true
      users:
        admin:
          password: admin
          roles:
            - authenticated-user
            - admin
        user:
          password: user
          roles:
            - authenticated-user
```

| Property | Purpose |
|----------|---------|
| `spring.config.activate.on-profile: default` | This section only activates for `default` profile |
| `spring.datasource.url` | H2 in-memory database with case-insensitive identifiers (like HANA) |
| `spring.sql.init.mode: always` | Runs SQL scripts (`schema-h2.sql`, `data.sql`) on every startup |
| `spring.sql.init.schema-locations` | Explicit path to H2 schema file |
| `spring.h2.console.enabled: true` | Enables web UI at `/h2-console` for debugging |
| `cds.datasource.auto-config.enabled: true` | CAP auto-detects H2 from datasource config |
| `cds.security.mock.enabled: true` | **CAP Mock Authentication** — creates test users without Spring Security config |
| `cds.security.mock.users` | Defines `admin/admin` and `user/user` with roles for testing |

#### Why Use CAP Mock Security?

Instead of writing a custom `UserDetailsService` with Spring Security, CAP provides **built-in mock authentication**:
- Simpler configuration (YAML only, no Java code for local users)
- Automatically integrates with CAP's authorization checks
- Uses Basic Auth — same as XSUAA in cloud (Bearer token from mock users)

---

### Section 3: CLOUD Profile

```yaml
---
spring:
  config:
    activate:
      on-profile: cloud

cds:
  datasource:
    auto-config:
      enabled: true
  security:
    xsuaa:
      enabled: true

logging:
  level:
    com.sap.cds: INFO
    com.tutorial: INFO
```

| Property | Purpose |
|----------|---------|
| `spring.config.activate.on-profile: cloud` | This section only activates when `SPRING_PROFILES_ACTIVE=cloud` |
| `cds.datasource.auto-config.enabled: true` | Auto-detects HANA from `VCAP_SERVICES` environment variable |
| `cds.security.xsuaa.enabled: true` | Enables OAuth2 authentication via XSUAA service |
| `logging.level: INFO` | Reduces log verbosity in production |

#### How Cloud Profile Gets Activated

The `mta.yaml` sets an environment variable on the Java app:
```yaml
properties:
  SPRING_PROFILES_ACTIVE: cloud
```

This automatically switches to:
- **HANA** database (from bound HDI container service)
- **XSUAA** authentication (from bound XSUAA service)

---

### Key Differences: Local vs. Cloud

| Aspect | Local (`default`) | Cloud (`cloud`) |
|--------|-------------------|-----------------|
| **Database** | H2 in-memory | SAP HANA Cloud |
| **Schema** | `schema-h2.sql` (auto-run) | HDI deployer (separate module) |
| **Sample Data** | `data.sql` (auto-run) | Must be inserted via API |
| **Authentication** | CAP Mock (Basic Auth) | XSUAA OAuth2 (Bearer token) |
| **Users** | `admin/admin`, `user/user` | BTP user assignments |

---

Create `srv/src/main/resources/application.yaml`:

```yaml
# =============================================
# Common configuration (all profiles)
# =============================================
spring:
  application:
    name: student-manager

cds:
  odata-v4:
    endpoint:
      path: /odata/v4              # OData endpoint base path

# Health check endpoints (unauthenticated for BTP health checks)
management:
  endpoints:
    web:
      exposure:
        include: health,info
  endpoint:
    health:
      show-details: when-authorized

logging:
  level:
    com.sap.cds: INFO
    com.tutorial: DEBUG

---
# =============================================
# LOCAL profile (default) — H2 in-memory database
# =============================================
spring:
  config:
    activate:
      on-profile: default
  datasource:
    url: jdbc:h2:mem:studentdb;DB_CLOSE_DELAY=-1;CASE_INSENSITIVE_IDENTIFIERS=TRUE
    driver-class-name: org.h2.Driver
  sql:
    init:
      mode: always                  # Auto-run schema and data SQL on startup
      schema-locations: classpath:schema-h2.sql    # Explicit schema file for H2
      continue-on-error: false      # Stop if SQL script fails
  h2:
    console:
      enabled: true                 # H2 web console at /h2-console

cds:
  datasource:
    auto-config:
      enabled: true
  security:
    mock:
      enabled: true                 # Mock authentication for local dev
      users:
        admin:
          password: admin
          roles:
            - authenticated-user
            - admin
        user:
          password: user
          roles:
            - authenticated-user

---
# =============================================
# CLOUD profile — SAP BTP Cloud Foundry
# =============================================
spring:
  config:
    activate:
      on-profile: cloud

cds:
  datasource:
    auto-config:
      enabled: true                 # Auto-detect HANA from VCAP_SERVICES
  security:
    xsuaa:
      enabled: true                 # Real OAuth2 via XSUAA

logging:
  level:
    com.sap.cds: INFO
    com.tutorial: INFO
```

---

## Step 10 - Security Configuration

This step creates a minimal `SecurityConfig` class to allow **unauthenticated access to health check endpoints**. This is required because Cloud Foundry performs health probes on `/actuator/health` before the app is fully started — if authentication is required, the health check fails and the app won't deploy.

### Why Do We Need This?

**Problem**: By default, Spring Security (included via CAP dependencies) blocks all requests, including health endpoints.

**Solution**: Create a security filter chain with `@Order(1)` that permits actuator endpoints before CAP's default security kicks in.

### What About OData Authentication?

For OData endpoints (`/odata/v4/**`), we rely on **CAP's built-in security** configured in `application.yaml`:

| Environment | Mechanism | Config |
|-------------|-----------|--------|
| **Local** | CAP Mock Authentication | `cds.security.mock.enabled: true` |
| **Cloud** | XSUAA OAuth2 | `cds.security.xsuaa.enabled: true` |

This approach is simpler than writing custom Spring Security filter chains — CAP handles authentication automatically based on the active profile.

### Security Filter Chain Explained

```
┌─────────────────────────────────────────────────────────────┐
│                    Incoming Request                         │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  @Order(1) actuatorSecurityFilterChain                      │
│  Matches: /actuator/**                                      │
│  Action: permitAll() for health, info; authenticated others │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼ (if not /actuator/**)
┌─────────────────────────────────────────────────────────────┐
│  CAP Default Security (auto-configured)                     │
│  Local: Mock users from application.yaml                    │
│  Cloud: XSUAA OAuth2 token validation                       │
└─────────────────────────────────────────────────────────────┘
```

### Key Annotations

| Annotation | Purpose |
|------------|---------|
| `@Configuration` | Marks this class as a Spring configuration |
| `@EnableWebSecurity` | Activates Spring Security's web security support |
| `@Order(1)` | Ensures this filter runs **before** CAP's default security |

### Code Breakdown

```java
@Bean
@Order(1)
public SecurityFilterChain actuatorSecurityFilterChain(HttpSecurity http) throws Exception {
    http
        .securityMatcher("/actuator/**")           // Only applies to /actuator/* paths
        .authorizeHttpRequests(authorize -> authorize
            .requestMatchers("/actuator/health", "/actuator/health/**", "/actuator/info")
                .permitAll()                        // Health & info: no auth required
            .anyRequest().authenticated()           // Other actuator endpoints: require auth
        );
    return http.build();
}
```

**Why not just `permitAll()` for all actuator endpoints?**

Security best practice: only expose what's needed. Health and info are safe; other actuator endpoints (like `/actuator/env`, `/actuator/beans`) could leak sensitive information.

---

Create `srv/src/main/java/com/tutorial/studentmanager/config/SecurityConfig.java`:

```java
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
            .securityMatcher("/actuator/**")
            .authorizeHttpRequests(authorize -> authorize
                .requestMatchers("/actuator/health", "/actuator/health/**", "/actuator/info").permitAll()
                .anyRequest().authenticated()
            );
        return http.build();
    }
}
```

---

## Step 11 - Build & Test Locally

```bash
# Build the project
mvn clean compile

# Run locally
cd srv
mvn spring-boot:run
```

Test endpoints:
- OData metadata: `GET http://localhost:8080/odata/v4/StudentService/$metadata`
- List students: `GET http://localhost:8080/odata/v4/StudentService/Students`
- Health check: `GET http://localhost:8080/actuator/health`

Authentication: Use Basic Auth `admin/admin` or `user/user`

Generated files after build:
- `srv/src/gen/java/` - Java interfaces from CDS models
- `srv/src/main/resources/edmx/csn.json` - Compiled CDS model
- `srv/src/main/resources/edmx/odata/v4/StudentService.xml` - OData EDMX metadata

---

## Step 12 - Add Cloud Dependencies

Update `srv/pom.xml` to add HANA and cloud dependencies:

```xml
<!-- HANA support -->
<dependency>
    <groupId>com.sap.cds</groupId>
    <artifactId>cds-feature-hana</artifactId>
    <scope>runtime</scope>
</dependency>

<!-- Cloud Foundry integration -->
<dependency>
    <groupId>com.sap.cds</groupId>
    <artifactId>cds-starter-cloudfoundry</artifactId>
</dependency>

<!-- Actuator for health checks -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
```

Update `package.json` with CDS production configuration:

```json
{
    "name": "student-manager",
    "version": "1.0.0",
    "scripts": {
        "build": "cds build --production",
        "build:hana": "cds build --for hana",
        "build:java": "cds build --for java",
        "build:all": "cds build --for hana && cd srv && mvn clean package -DskipTests",
        "build:mta": "cds build --for hana && mbt build -t mta_archives/",
        "deploy": "cf deploy mta_archives/student-manager_1.0.0.mtar"
    },
    "dependencies": {
        "@sap/cds": "^8",
        "express": "^4"
    },
    "devDependencies": {
        "@sap/cds-dk": "^8"
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

---

## Step 13 - Deployment Descriptors

### XSUAA Security (`xs-security.json`):

```json
{
  "xsappname": "student-manager",
  "tenant-mode": "dedicated",
  "scopes": [
    { "name": "$XSAPPNAME.Read", "description": "Read access" },
    { "name": "$XSAPPNAME.Write", "description": "Write access" }
  ],
  "role-templates": [
    {
      "name": "Viewer",
      "description": "Read-only access",
      "scope-references": ["$XSAPPNAME.Read"]
    },
    {
      "name": "Editor",
      "description": "Full access",
      "scope-references": ["$XSAPPNAME.Read", "$XSAPPNAME.Write"]
    }
  ],
  "role-collections": [
    {
      "name": "StudentManager_Viewer",
      "description": "View students",
      "role-template-references": ["$XSAPPNAME.Viewer"]
    },
    {
      "name": "StudentManager_Editor",
      "description": "Manage students",
      "role-template-references": ["$XSAPPNAME.Editor"]
    }
  ],
  "oauth2-configuration": {
    "redirect-uris": ["https://*.cfapps.*.hana.ondemand.com/**"]
  }
}
```

### HDI Deployer (`db/package.json`):

⚠️ **IMPORTANT**: Must include `hdb` dependency for database connectivity!

```json
{
    "name": "student-manager-db",
    "version": "1.0.0",
    "dependencies": {
        "@sap/hdi-deploy": "^5",
        "hdb": "^0.19.0"
    },
    "engines": {
        "node": ">=18"
    },
    "scripts": {
        "start": "node node_modules/@sap/hdi-deploy/deploy.js"
    }
}
```

Run `npm install` in db folder:
```bash
cd db && npm install && cd ..
```

### AppRouter (`approuter/package.json`):

```json
{
    "name": "student-manager-approuter",
    "version": "1.0.0",
    "dependencies": {
        "@sap/approuter": "^16"
    },
    "scripts": {
        "start": "node node_modules/@sap/approuter/approuter.js"
    }
}
```

### AppRouter Config (`approuter/xs-app.json`):

```json
{
    "welcomeFile": "/odata/v4/StudentService/",
    "authenticationMethod": "route",
    "routes": [
        {
            "source": "^/odata/(.*)$",
            "target": "/odata/$1",
            "destination": "srv-api",
            "authenticationType": "xsuaa"
        }
    ]
}
```

### MTA Descriptor (`mta.yaml`):

⚠️ **IMPORTANT**: Must specify Java 21 runtime!

```yaml
_schema-version: "3.1"
ID: student-manager
version: 1.0.0
description: Student Manager CAP Java Application

parameters:
  enable-parallel-deployments: true

build-parameters:
  before-all:
    - builder: custom
      commands:
        - npm install --production

modules:
  # Java Service Module
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
      - name: student-manager-logging
      - name: student-manager-autoscaler

  # Database Deployer
  - name: student-manager-db-deployer
    type: hdb
    path: db
    parameters:
      buildpack: nodejs_buildpack
      memory: 256M
    build-parameters:
      builder: custom
      commands:
        - npm install --production
    requires:
      - name: student-manager-db

  # AppRouter
  - name: student-manager-approuter
    type: approuter.nodejs
    path: approuter
    parameters:
      memory: 256M
    requires:
      - name: student-manager-xsuaa
      - name: srv-api
        group: destinations
        properties:
          name: srv-api
          url: ~{srv-url}
          forwardAuthToken: true

resources:
  # HANA HDI Container
  - name: student-manager-db
    type: com.sap.xs.hdi-container
    parameters:
      service: hana
      service-plan: hdi-shared
      service-keys:
        - name: student-manager-db-key

  # XSUAA Service
  - name: student-manager-xsuaa
    type: org.cloudfoundry.managed-service
    parameters:
      service: xsuaa
      service-plan: application
      path: ./xs-security.json
      service-keys:
        - name: student-manager-xsuaa-key

  # Application Logging
  - name: student-manager-logging
    type: org.cloudfoundry.managed-service
    parameters:
      service: application-logs
      service-plan: lite

  # Autoscaler
  - name: student-manager-autoscaler
    type: org.cloudfoundry.managed-service
    parameters:
      service: autoscaler
      service-plan: standard
```

---

## Step 14 - Pre-Deployment: Create HANA Cloud Instance

⚠️ **CRITICAL**: You MUST create a HANA Cloud instance BEFORE deploying!

### Option A: Via BTP Cockpit

1. Go to [SAP BTP Cockpit](https://cockpit.hanatrial.ondemand.com/)
2. Navigate to your **Subaccount** → **Service Marketplace**
3. Search for **"SAP HANA Cloud"**
4. Click **Create** → Select plan: **`hana-free`** (for trial)
5. Set instance name and password
6. **Wait 10-20 minutes** for status to be "Running"

### Option B: Via CF CLI

Create `hana-cloud-config.json`:
```json
{
    "data": {
        "memory": 16,
        "systempassword": "YourSecurePassword123!",
        "edition": "cloud",
        "vcpu": 1,
        "whitelistIPs": ["0.0.0.0/0"]
    }
}
```

```bash
cf create-service hana-cloud hana-free student-manager-hana -c hana-cloud-config.json
```

### Verify HANA is Running:
```bash
cf services
# Should show: student-manager-hana  hana-cloud  hana-free  create succeeded
```

---

## Step 15 - Build & Deploy

### Understanding CDS Build

⚠️ **IMPORTANT**: CAP has separate build tasks for different targets!

| Command | Output | Purpose |
|---------|--------|---------|
| `cds build --for java` | `srv/src/main/resources/edmx/` | Java runtime (automatic with `mvn package`) |
| `cds build --for hana` | `db/src/gen/` | HANA tables/views (must run manually!) |

**`mvn clean package` does NOT generate HANA artifacts!**

### Build Commands

```bash
# Login to Cloud Foundry
cf login -a https://api.cf.us10-001.hana.ondemand.com

# Option A: Use npm script (recommended)
npm run build:mta

# Option B: Manual commands
cds build --for hana    # Generate db/src/gen/*.hdbtable, *.hdbview
mbt build               # Build MTA archive (includes mvn package)
```

### Deploy

```bash
cf deploy mta_archives/student-manager_1.0.0.mtar
```

---

## Step 16 - Verify Deployment

```bash
# Check applications
cf apps

# Check services
cf services

# Check logs
cf logs student-manager-srv --recent

# Get application URL
cf app student-manager-srv
```

---

## Step 17 - Test Cloud Deployment

Get the application URL from `cf apps` output.

### Get OAuth Token:
```bash
# Get XSUAA credentials
cf env student-manager-srv | grep -A 50 xsuaa
```

Use the `clientid`, `clientsecret`, and `url` to get a token:
```bash
curl -X POST "<xsuaa-url>/oauth/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials&client_id=<clientid>&client_secret=<clientsecret>"
```

### Test API:
```bash
curl -H "Authorization: Bearer <token>" \
  https://<your-app-url>/odata/v4/StudentService/Students
```

---

## Troubleshooting

### Error: "Table TUTORIAL_STUDENTS not found" (500 Error)

**Cause**: HANA artifacts not deployed. Missing `db/src/gen/` folder.

**Solution**:
```bash
cds build --for hana
npm run build:mta
cf deploy mta_archives/student-manager_1.0.0.mtar
```

### Error: "Could not create service student-manager-db"

**Cause**: HANA Cloud instance not created or not running.

**Solution**: Create HANA Cloud instance (see Step 14).

### Error: "HANA Database instance is stopped"

**Cause**: Trial HANA instances auto-stop after inactivity.

**Solution**:
1. Go to BTP Cockpit → SAP HANA Cloud → Subscriptions
2. Open HANA Cloud Central dashboard
3. Start your HANA instance

### Error: "UnsupportedClassVersionError" (Java 65.0 vs 61.0)

**Cause**: App compiled with Java 21, runtime using Java 17.

**Solution**: Ensure `mta.yaml` has:
```yaml
JBP_CONFIG_SAP_MACHINE_JRE: '{ version: 21.+ }'
```

### Error: "requires a peer of '@sap/hana-client' or 'hdb'"

**Cause**: Missing database client in `db/package.json`.

**Solution**: Add `"hdb": "^0.19.0"` to dependencies and run `npm install`.

---

## Summary of Key Files

| File | Purpose |
|------|---------|
| `db/schema.cds` | Data model definition |
| `srv/service.cds` | Service definition |
| `srv/pom.xml` | Java dependencies |
| `package.json` | CDS config & npm scripts |
| `mta.yaml` | Deployment descriptor |
| `xs-security.json` | XSUAA roles & scopes |
| `db/package.json` | HDI deployer config |
| `approuter/xs-app.json` | Routing config |

## Quick Reference Commands

```bash
# Local development
cd srv && mvn spring-boot:run

# Build for cloud
npm run build:mta

# Deploy to cloud
cf deploy mta_archives/student-manager_1.0.0.mtar

# View logs
cf logs student-manager-srv --recent

# Restart app
cf restart student-manager-srv