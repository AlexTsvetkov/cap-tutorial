# CAP Java Workshop — Live Coding Presentation Script

> **Duration:** ~2 hours  
> **Audience:** Java developers, SAP BTP developers  
> **Format:** Live screen-sharing, building a CAP Java project from scratch  
> **Goal:** Build and deploy a Student Management app using SAP CAP Java SDK

---

## Table of Contents

1. [Prerequisites & Tool Installation](#step-1--prerequisites--tool-installation)
2. [Create GitHub Repository & Clone](#step-2--create-github-repository--clone)
3. [Scaffold CAP Java Project with Maven](#step-3--scaffold-cap-java-project-with-maven)
4. [Understand the Project Structure & pom.xml](#step-4--understand-the-project-structure--pomxml)
5. [Define the Students Entity (CDS Model)](#step-5--define-the-students-entity-cds-model)
6. [Create the Students Service with CRUD](#step-6--create-the-students-service-with-crud)
7. [Add Initial Data](#step-7--add-initial-data)
8. [Configure application.yaml](#step-8--configure-applicationyaml)
9. [Build the App & Explore Generated Files](#step-9--build-the-app--explore-generated-files)
10. [Run Locally & Test with Postman](#step-10--run-locally--test-with-postman)
11. [Add BTP Services (HANA, XSUAA, Logging, Autoscaler)](#step-11--add-btp-services-hana-xsuaa-logging-autoscaler)
12. [Create & Explain mta.yaml](#step-12--create--explain-mtayaml)
13. [Configure Security (OAuth2 for Cloud, Basic for Local)](#step-13--configure-security-oauth2-for-cloud-basic-for-local)
14. [Deploy to SAP BTP Trial](#step-14--deploy-to-sap-btp-trial)
15. [Explain Deployment & Runtime on BTP](#step-15--explain-deployment--runtime-on-btp)

---

## Step 1 — Prerequisites & Tool Installation

### 🎤 What to say

> "Before we start coding, let's make sure we have all required tools installed. CAP Java projects need Node.js for the CDS compiler, Java + Maven for the backend, and the Cloud Foundry CLI for deployment."

### Required tools

| Tool | Purpose | Verify command |
|------|---------|---------------|
| **Node.js** (≥18) | CDS compiler, npm packages | `node -v` |
| **Java JDK** (17+) | Java backend runtime | `java -version` |
| **Maven** (3.8+) | Build tool for Java | `mvn -version` |
| **@sap/cds-dk** | CDS development kit (CLI) | `cds version` |
| **Cloud Foundry CLI** | Deploy to SAP BTP | `cf version` |
| **MBT (MTA Build Tool)** | Build MTA archives for deployment | `mbt --version` |

### Commands to install

```bash
# 1. Install CDS Development Kit globally
npm install -g @sap/cds-dk

# Verify installation
cds version
```

**🔍 Explain:** `@sap/cds-dk` gives us the `cds` CLI — the main tool for CAP development. It compiles CDS models, generates artifacts, initializes projects, and more.

```bash
# 2. Install MTA Build Tool globally
npm install -g mbt

# Verify installation
mbt --version
```

**🔍 Explain:** `mbt` (MTA Build Tool) packages our multi-module application into an `.mtar` archive that can be deployed to SAP BTP Cloud Foundry.

```bash
# 3. Install Cloud Foundry CLI (macOS)
brew install cloudfoundry/tap/cf-cli@8

# Verify
cf version
```

**🔍 Explain:** The CF CLI is how we interact with SAP BTP Cloud Foundry — deploying apps, checking logs, managing services.

```bash
# 4. Install CF MTA plugin (for deploying MTA archives)
cf install-plugin multiapps

# Verify
cf plugins | grep multiapps
```

**🔍 Explain:** The `multiapps` plugin adds the `cf deploy` command that understands MTA archives.

---

## Step 2 — Create GitHub Repository & Clone

### 🎤 What to say

> "Let's start by creating a GitHub repository first, then clone it to have version control properly set up from the beginning. This is the recommended workflow for collaborative projects."

### Step 2.1: Create GitHub Repository

1. Go to [GitHub](https://github.com) and sign in
2. Click **"New repository"** (or go to https://github.com/new)
3. Configure the repository:
   - **Repository name:** `cap-tutorial`
   - **Description:** "CAP Java Tutorial - Student Manager Application"
   - **Visibility:** Public (or Private)
   - ✅ **Add a README file** (optional)
   - ✅ **Add .gitignore:** Select "Maven" template
   - **License:** Choose if needed (e.g., MIT)
4. Click **"Create repository"**

### Step 2.2: Clone the Repository

```bash
# Clone the repository (replace with your GitHub username)
git clone git@github.com:YOUR_USERNAME/cap-tutorial.git

# Or using HTTPS:
# git clone https://github.com/YOUR_USERNAME/cap-tutorial.git

# Move into the cloned folder
cd cap-tutorial

# Verify
ls -la
git status
git remote -v
```

### Step 2.3: Update .gitignore for CAP Java

The GitHub-generated `.gitignore` is for generic Maven projects. Let's update it for CAP Java:

```bash
cat > .gitignore << 'EOF'
# Maven
target/
*.jar
!.mvn/wrapper/maven-wrapper.jar

# Node.js
node_modules/

# CAP generated files
srv/src/gen/
db/src/gen/

# MTA build artifacts
*.mtar
mta_archives/

# IDE files
.idea/
*.iml
.vscode/

# OS files
.DS_Store
Thumbs.db

# Logs
*.log

out/
EOF

# Commit the updated .gitignore
git add .gitignore
git commit -m "chore: update .gitignore for CAP Java project"
git push
```

**🔍 Explain:**
- Creating the repo on GitHub first ensures proper remote setup
- Cloning gives us a clean working directory with Git already configured
- The `.gitignore` excludes:
  - **Maven build outputs:** `target/`, `*.jar`
  - **Node modules:** `node_modules/`
  - **CAP generated files:** `srv/src/gen/`, `db/src/gen/` (regenerated on every build)
  - **MTA archives:** `*.mtar`, `mta_archives/`
  - **IDE files:** `.idea/`, `.vscode/`

---

## Step 3 — Scaffold CAP Java Project with Maven

### 🎤 What to say

> "CAP provides a Maven archetype that scaffolds the entire project structure for us — the parent POM, the service module, the database module, and all the CDS configuration."

### Command

```bash
# Scaffold CAP Java project using the official Maven archetype
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

```bash
# Move into the generated project
cd student-manager

# Install npm dependencies (needed for CDS compiler)
npm install

# Verify project structure
ls -la
```

**🔍 Explain:**
- The Maven archetype generates a **multi-module Maven project**:
  - `srv/` — Java service module (Spring Boot application)
  - `db/` — Database module (CDS models, HDI artifacts)
  - `app/` — Optional UI module
- `npm install` pulls in `@sap/cds` which is the CDS compiler used during Maven build
- The parent `pom.xml` orchestrates the build of all modules

### What got generated

```
student-manager/
├── pom.xml              ← Parent POM (multi-module)
├── package.json         ← Node.js dependencies for CDS
├── srv/
│   ├── pom.xml          ← Service module POM
│   └── src/main/
│       ├── java/        ← Java source code
│       └── resources/   ← application.yaml, CDS artifacts
├── db/
│   ├── package.json     ← DB deployer dependencies
│   └── schema.cds       ← CDS data model (we'll edit this)
└── app/                 ← Optional UI module
```

---

## Step 4 — Understand the Project Structure & pom.xml

### 🎤 What to say

> "Let's look at the generated POM files. CAP Java uses a parent-child Maven structure, and there are some important dependencies and plugins to understand."

### Open the parent `pom.xml` and explain

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" ...>
    <modelVersion>4.0.0</modelVersion>

    <groupId>com.tutorial</groupId>
    <artifactId>student-manager-parent</artifactId>
    <version>1.0.0</version>
    <packaging>pom</packaging>                <!-- ① Multi-module parent -->

    <properties>
        <java.version>17</java.version>
        <cds.services.version>3.7.0</cds.services.version>       <!-- ② CAP SDK version -->
        <spring.boot.version>3.4.1</spring.boot.version>          <!-- ③ Spring Boot version -->
    </properties>

    <modules>
        <module>srv</module>                   <!-- ④ Child module: service -->
    </modules>

    <dependencyManagement>
        <dependencies>
            <!-- ⑤ CAP Java SDK BOM — manages all CAP dependency versions -->
            <dependency>
                <groupId>com.sap.cds</groupId>
                <artifactId>cds-services-bom</artifactId>
                <version>${cds.services.version}</version>
                <type>pom</type>
                <scope>import</scope>
            </dependency>

            <!-- ⑥ Spring Boot BOM — manages all Spring dependency versions -->
            <dependency>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-dependencies</artifactId>
                <version>${spring.boot.version}</version>
                <type>pom</type>
                <scope>import</scope>
            </dependency>
        </dependencies>
    </dependencyManagement>
</project>
```

**🔍 Explain line by line:**

| # | Element | What it does |
|---|---------|-------------|
| ① | `<packaging>pom</packaging>` | This is a **parent POM** — it doesn't produce a JAR, it orchestrates child modules |
| ② | `cds.services.version` | The version of the CAP Java SDK. All CAP dependencies use this version |
| ③ | `spring.boot.version` | CAP Java is built on top of Spring Boot |
| ④ | `<modules>` | Lists child modules. Maven builds them in order |
| ⑤ | `cds-services-bom` | **Bill of Materials** — imports all CAP Java SDK dependency versions so you don't have to specify versions individually |
| ⑥ | `spring-boot-dependencies` | Same idea — imports all Spring Boot managed versions |

### Open the `srv/pom.xml` and explain key dependencies

```xml
<dependencies>
    <!-- CAP Java SDK starter — brings in Spring Boot + CDS runtime -->
    <dependency>
        <groupId>com.sap.cds</groupId>
        <artifactId>cds-starter-spring-boot</artifactId>
    </dependency>

    <!-- OData V4 protocol adapter — exposes CDS services as OData endpoints -->
    <dependency>
        <groupId>com.sap.cds</groupId>
        <artifactId>cds-adapter-odata-v4</artifactId>
        <scope>runtime</scope>
    </dependency>

    <!-- H2 in-memory database — for local development without HANA -->
    <dependency>
        <groupId>com.h2database</groupId>
        <artifactId>h2</artifactId>
        <scope>runtime</scope>
    </dependency>
</dependencies>
```

**🔍 Explain:**

| Dependency | Purpose |
|-----------|---------|
| `cds-starter-spring-boot` | The **main starter** — bootstraps the CAP Java runtime on top of Spring Boot. It auto-configures CDS services, event handlers, and data access |
| `cds-adapter-odata-v4` | Translates CDS service definitions into **OData V4 endpoints** automatically. You define a CDS service → you get an OData API for free |
| `h2` | Lightweight in-memory SQL database for **local development**. In production, we'll use SAP HANA |

### Explain the CDS Maven Plugin

```xml
<plugin>
    <groupId>com.sap.cds</groupId>
    <artifactId>cds-maven-plugin</artifactId>
    <executions>
        <execution>
            <id>cds.generate</id>
            <goals>
                <goal>generate</goal>    <!-- Generates Java interfaces from CDS models -->
            </goals>
        </execution>
    </executions>
</plugin>
```

**🔍 Explain:** This plugin runs during `mvn compile` and does two critical things:
1. **Compiles CDS models** (`.cds` files) into a `csn.json` (Core Schema Notation) 
2. **Generates Java interfaces** from your CDS entities and services — these are the typed POJOs you'll use in your event handlers

---

## Step 5 — Define the Students Entity (CDS Model)

### 🎤 What to say

> "Now let's define our data model using CDS — the Core Data Services language. CDS is a human-readable, declarative language for defining data models and services. It's the heart of CAP."

### Command: Edit `db/schema.cds`

```bash
cat > db/schema.cds << 'EOF'
namespace tutorial;

using { cuid, managed } from '@sap/cds/common';

/**
 * Student entity — represents a student in our system.
 * 
 * `cuid` provides: ID (UUID, auto-generated key)
 * `managed` provides: createdAt, createdBy, modifiedAt, modifiedBy
 */
entity Students : cuid, managed {
    firstName    : String(100) @mandatory;
    lastName     : String(100) @mandatory;
    email        : String(255) @mandatory;
    dateOfBirth  : Date;
    status       : String(20) default 'ACTIVE';
}
EOF
```

**🔍 Explain step by step:**

| Element | What it does |
|---------|-------------|
| `namespace tutorial` | Scopes all entities under `tutorial.*` — prevents naming conflicts |
| `using { cuid, managed }` | Imports reusable **aspects** from the CAP standard library |
| `cuid` | Adds `ID : UUID` as the primary key — auto-generated |
| `managed` | Adds `createdAt`, `createdBy`, `modifiedAt`, `modifiedBy` — automatically populated by CAP |
| `@mandatory` | Annotation that marks a field as required (OData nullable=false) |
| `String(100)` | CDS type that maps to `VARCHAR(100)` in SQL, `Edm.String` in OData |
| `default 'ACTIVE'` | Default value — if not provided during INSERT, this value is used |

> 💡 **Key concept:** In CAP, you define your model ONCE in CDS, and it gets compiled into:
> - SQL DDL for the database (H2, HANA, PostgreSQL)
> - OData EDMX metadata for the API layer
> - Java interfaces for your code

---

## Step 6 — Create the Students Service with CRUD

### 🎤 What to say

> "Now we expose our Students entity as an OData service. In CAP, you define a service in CDS — and you get full CRUD operations for FREE. No controllers, no DAO layer, no boilerplate."

### Command: Create `srv/service.cds`

```bash
cat > srv/service.cds << 'EOF'
using { tutorial } from '../db/schema';

/**
 * Student Management Service — exposes Students as an OData V4 endpoint.
 * 
 * By default, CAP provides full CRUD (Create, Read, Update, Delete)
 * for every entity exposed in the service.
 */
service StudentService {

    entity Students as projection on tutorial.Students;

}
EOF
```

**🔍 Explain:**

| Element | What it does |
|---------|-------------|
| `using { tutorial }` | Imports the namespace from our schema file |
| `service StudentService` | Defines an OData service named `StudentService` |
| `entity Students as projection on tutorial.Students` | **Exposes** the `Students` entity through this service. `projection` means it's a view — you can filter, rename, or exclude fields |

> 💡 **Key takeaway:** This is ALL you need for a fully functional REST/OData API! CAP automatically provides:
> - `GET /odata/v4/StudentService/Students` — Read all
> - `GET /odata/v4/StudentService/Students({id})` — Read by ID
> - `POST /odata/v4/StudentService/Students` — Create
> - `PATCH /odata/v4/StudentService/Students({id})` — Update
> - `DELETE /odata/v4/StudentService/Students({id})` — Delete
> - Full OData query support: `$filter`, `$select`, `$orderby`, `$top`, `$skip`, `$count`

### Optional: Add a Custom Event Handler

If you want to add custom business logic (e.g., validation), create a Java handler:

```bash
mkdir -p srv/src/main/java/com/tutorial/studentmanager/handlers

cat > srv/src/main/java/com/tutorial/studentmanager/handlers/StudentServiceHandler.java << 'EOF'
package com.tutorial.studentmanager.handlers;

import com.sap.cds.services.handler.EventHandler;
import com.sap.cds.services.handler.annotations.Before;
import com.sap.cds.services.handler.annotations.ServiceName;
import com.sap.cds.services.cds.CqnService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Map;

@Component
@ServiceName("StudentService")
public class StudentServiceHandler implements EventHandler {

    private static final Logger log = LoggerFactory.getLogger(StudentServiceHandler.class);

    /**
     * Validation: runs BEFORE every CREATE operation on Students.
     * Ensures email contains '@' character.
     */
    @Before(event = CqnService.EVENT_CREATE, entity = "StudentService.Students")
    public void validateStudentEmail(List<Map<String, Object>> students) {
        for (Map<String, Object> student : students) {
            String email = (String) student.get("email");
            if (email != null && !email.contains("@")) {
                throw new IllegalArgumentException("Invalid email: " + email);
            }
            log.info("Creating student: {} {}", student.get("firstName"), student.get("lastName"));
        }
    }
}
EOF
```

**🔍 Explain:**

| Element | What it does |
|---------|-------------|
| `@ServiceName("StudentService")` | Binds this handler to our CDS service |
| `implements EventHandler` | CAP marker interface — tells the framework this class handles events |
| `@Before(event = CqnService.EVENT_CREATE)` | This method runs **before** every CREATE request |
| `entity = "StudentService.Students"` | Only for the Students entity |
| No DAO/Repository needed | CAP handles persistence automatically — you only write business logic |

---

## Step 7 — Add Initial Data

### 🎤 What to say

> "Let's add some test data so we have something to see when we run the app. For local development with H2, we use SQL scripts that Spring Boot auto-executes on startup."

### Command: Create initial data SQL

```bash
cat > srv/src/main/resources/schema.sql << 'EOF'
-- This file is auto-managed by CAP for H2 database.
-- During local development, CAP + H2 will create tables from CDS models.
-- This file can contain additional DDL if needed.
EOF

cat > srv/src/main/resources/data.sql << 'EOF'
-- =============================================
-- Initial test data for Student Manager
-- =============================================

INSERT INTO tutorial_Students (ID, firstName, lastName, email, dateOfBirth, status) VALUES
    ('11111111-1111-1111-1111-111111111111', 'Alice', 'Johnson', 'alice@example.com', '2000-05-14', 'ACTIVE'),
    ('22222222-2222-2222-2222-222222222222', 'Bob', 'Smith', 'bob@example.com', '1999-11-30', 'ACTIVE'),
    ('33333333-3333-3333-3333-333333333333', 'Carol', 'Williams', 'carol@example.com', '2001-02-20', 'INACTIVE');
EOF
```

**🔍 Explain:**
- The table name `tutorial_Students` comes from the CDS namespace: `tutorial.Students` → `tutorial_Students` (dots become underscores)
- The `ID` column is a UUID (from the `cuid` aspect) — we provide fixed UUIDs for test data so they're predictable
- Spring Boot's `spring.sql.init.mode: always` auto-runs `data.sql` on startup
- **In production (HANA):** you'd use CSV files or `.hdbtabledata` instead — this is H2-only

---

## Step 8 — Configure application.yaml

### 🎤 What to say

> "The `application.yaml` is where we configure Spring Boot + CAP behavior. CAP Java uses Spring profiles to differentiate between local development and cloud deployment."

### Command: Create application.yaml

```bash
cat > srv/src/main/resources/application.yaml << 'YAML'
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

# Health check endpoints
management:
  endpoints:
    web:
      exposure:
        include: health,info

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
      mode: always                  # Auto-run data.sql on startup
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
YAML
```

**🔍 Explain section by section:**

### Common section (applies to all profiles)
| Setting | Purpose |
|---------|---------|
| `cds.odata-v4.endpoint.path` | All OData endpoints will be under `/odata/v4/` |
| `management.endpoints` | Exposes health check at `/actuator/health` — BTP uses this for liveness probes |

### Local profile (`default`)
| Setting | Purpose |
|---------|---------|
| `spring.datasource.url` | H2 in-memory database — data is lost on restart |
| `CASE_INSENSITIVE_IDENTIFIERS=TRUE` | Makes H2 behave like HANA (case-insensitive column names) |
| `spring.sql.init.mode: always` | Runs `data.sql` every startup to seed test data |
| `cds.security.mock.enabled: true` | **No real OAuth2 locally!** Uses simple username/password mock users |
| Mock users `admin/admin`, `user/user` | Pre-configured test users with different roles |

### Cloud profile
| Setting | Purpose |
|---------|---------|
| `on-profile: cloud` | Activated when `SPRING_PROFILES_ACTIVE=cloud` is set (in mta.yaml) |
| `cds.datasource.auto-config` | CAP automatically reads `VCAP_SERVICES` to connect to HANA |
| `cds.security.xsuaa.enabled` | Uses **real OAuth2 JWT tokens** from XSUAA service |

> 💡 **Key concept:** The `---` separator in YAML creates separate documents. Spring Boot treats each as a profile-specific override.

---

## Step 9 — Build the App & Explore Generated Files

### 🎤 What to say

> "Let's build the project and see what CAP generates for us. This is where the magic happens — CDS models get compiled into Java interfaces, SQL schemas, and OData metadata."

### Command: Build

```bash
# Full Maven build
mvn clean compile
```

### Explore generated files

```bash
# 1. Generated Java interfaces from CDS models
ls -la srv/src/gen/java/

# You'll see files like:
# - studentservice/Students.java      ← Java interface for the entity
# - studentservice/Students_.java     ← Static metadata class
# - studentservice/StudentService.java ← Service interface
```

**🔍 Explain the generated Java interface:**

```java
// This is AUTO-GENERATED by the CDS Maven Plugin from your CDS model.
// DO NOT edit this file — it gets regenerated on every build.
public interface Students extends Map<String, Object> {
    String ID = "ID";
    String FIRST_NAME = "firstName";
    String LAST_NAME = "lastName";
    String EMAIL = "email";
    
    String getId();
    void setId(String id);
    String getFirstName();
    void setFirstName(String firstName);
    // ... getters/setters for all fields
    
    static Students create() { ... }  // Factory method
}
```

> 💡 These generated interfaces give you **type-safe access** to CDS entities in Java code — no magic strings needed.

```bash
# 2. Generated CSN (Core Schema Notation) — the compiled CDS model
cat srv/src/main/resources/edmx/csn.json | head -50
```

**🔍 Explain:** `csn.json` is the **compiled representation** of all your CDS files. The CAP Java runtime reads this at startup to understand your data model and service definitions.

```bash
# 3. Generated OData EDMX metadata
cat srv/src/main/resources/edmx/odata/v4/StudentService.xml
```

**🔍 Explain:** This is the **OData V4 metadata document** (`$metadata`). It describes your API in a standard format that any OData client can understand — entity types, properties, navigation properties, and service endpoints.

---

## Step 10 — Run Locally & Test with Postman

### 🎤 What to say

> "Let's start the application and see our OData API in action. We'll test CRUD operations using Postman and explore OData query capabilities."

### Command: Run the app

```bash
# Run with Maven Spring Boot plugin
cd srv && mvn spring-boot:run
```

Or from the project root:

```bash
mvn -pl srv spring-boot:run
```

You should see output like:
```
  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
...
INFO  - Started Application in 4.5 seconds
INFO  - Registered service: StudentService
INFO  - OData V4 endpoint: /odata/v4/StudentService
```

### Test in Postman

> 💡 **Authentication:** For local development, use **Basic Auth** with `admin/admin` or `user/user`

#### 1. Get OData metadata

```
GET http://localhost:8080/odata/v4/StudentService/$metadata
Authorization: Basic admin:admin
```

**🔍 Explain:** The `$metadata` endpoint returns the EDMX document — a machine-readable description of your entire API. OData clients use this for auto-discovery.

#### 2. Read all Students

```
GET http://localhost:8080/odata/v4/StudentService/Students
Authorization: Basic admin:admin
```

Response:
```json
{
    "@odata.context": "$metadata#Students",
    "value": [
        {
            "ID": "11111111-1111-1111-1111-111111111111",
            "firstName": "Alice",
            "lastName": "Johnson",
            "email": "alice@example.com",
            "dateOfBirth": "2000-05-14",
            "status": "ACTIVE",
            "createdAt": null,
            "modifiedAt": null
        },
        ...
    ]
}
```

#### 3. Read a single Student by ID

```
GET http://localhost:8080/odata/v4/StudentService/Students(11111111-1111-1111-1111-111111111111)
Authorization: Basic admin:admin
```

#### 4. OData query examples

```bash
# $select — only return specific fields
GET .../Students?$select=firstName,lastName,email

# $filter — server-side filtering
GET .../Students?$filter=status eq 'ACTIVE'
GET .../Students?$filter=contains(email, 'alice')
GET .../Students?$filter=dateOfBirth gt 2000-01-01

# $orderby — sorting
GET .../Students?$orderby=lastName asc

# $top and $skip — pagination
GET .../Students?$top=2&$skip=1

# $count — get total count
GET .../Students/$count

# Combine them
GET .../Students?$filter=status eq 'ACTIVE'&$select=firstName,email&$orderby=firstName&$top=10
```

**🔍 Explain:** These OData query parameters are **all handled automatically by CAP**. You didn't write a single line of query logic — CAP translates `$filter` into SQL `WHERE`, `$orderby` into `ORDER BY`, etc.

#### 5. Create a new Student

```
POST http://localhost:8080/odata/v4/StudentService/Students
Authorization: Basic admin:admin
Content-Type: application/json

{
    "firstName": "David",
    "lastName": "Brown",
    "email": "david@example.com",
    "dateOfBirth": "1998-07-15",
    "status": "ACTIVE"
}
```

> Notice: We don't provide `ID` — the `cuid` aspect auto-generates a UUID!

#### 6. Update a Student (PATCH)

```
PATCH http://localhost:8080/odata/v4/StudentService/Students(11111111-1111-1111-1111-111111111111)
Authorization: Basic admin:admin
Content-Type: application/json

{
    "status": "GRADUATED"
}
```

#### 7. Delete a Student

```
DELETE http://localhost:8080/odata/v4/StudentService/Students(33333333-3333-3333-3333-333333333333)
Authorization: Basic admin:admin
```

#### 8. Check Health endpoint

```
GET http://localhost:8080/actuator/health
```

**🎤 Summary:** With just a few lines of CDS and zero Java controllers, we have a full-featured OData V4 API with filtering, sorting, pagination, CRUD operations, and auto-generated metadata.

---

## Step 11 — Add BTP Services (HANA, XSUAA, Logging, Autoscaler)

### 🎤 What to say

> "For cloud deployment, we need to add SAP BTP service dependencies. Instead of H2, we'll use HANA. Instead of mock auth, we'll use XSUAA (OAuth2). We'll also add logging and autoscaler."

### Step 11.1: Add HANA & Cloud Foundry dependencies to `srv/pom.xml`

Add these dependencies inside `<dependencies>`:

```xml
<!-- HANA database support — connects to SAP HANA Cloud -->
<dependency>
    <groupId>com.sap.cds</groupId>
    <artifactId>cds-feature-hana</artifactId>
</dependency>

<!-- Cloud Foundry integration — reads VCAP_SERVICES, enables XSUAA -->
<dependency>
    <groupId>com.sap.cds</groupId>
    <artifactId>cds-starter-cloudfoundry</artifactId>
    <scope>runtime</scope>
</dependency>

<!-- Spring Boot Actuator — health checks used by BTP -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
```

**🔍 Explain each dependency:**

| Dependency | Purpose |
|-----------|---------|
| `cds-feature-hana` | Enables CAP to generate **HANA-specific SQL** and connect to HANA Cloud via HDI container |
| `cds-starter-cloudfoundry` | Auto-reads **VCAP_SERVICES** environment variable (injected by CF) to discover bound services (HANA, XSUAA). Also integrates with XSUAA for JWT validation |
| `spring-boot-starter-actuator` | Provides `/actuator/health` endpoint that BTP uses to check if your app is alive |

### Step 11.2: Configure `package.json` for production

```bash
cat > package.json << 'EOF'
{
    "name": "student-manager",
    "version": "1.0.0",
    "private": true,
    "dependencies": {
        "@sap/cds": "^8",
        "@sap/cds-dk": "^8",
        "express": "^4"
    },
    "scripts": {
        "build": "cds build --production"
    },
    "cds": {
        "requires": {
            "db": {
                "kind": "sql"
            },
            "[production]": {
                "db": {
                    "kind": "hana"
                },
                "auth": {
                    "kind": "xsuaa"
                }
            }
        }
    }
}
EOF
```

**🔍 Explain the `cds.requires` section:**

| Config | Meaning |
|--------|---------|
| `"db": { "kind": "sql" }` | Default: use generic SQL (H2 for local) |
| `[production].db.kind: "hana"` | In production profile: use HANA, generate HDI artifacts |
| `[production].auth.kind: "xsuaa"` | In production: authenticate via SAP XSUAA (OAuth2 JWT tokens) |

### Step 11.3: Create `xs-security.json` (XSUAA Configuration)

```bash
cat > xs-security.json << 'EOF'
{
    "xsappname": "student-manager",
    "tenant-mode": "dedicated",
    "description": "Student Manager OAuth2 Security",
    "scopes": [
        {
            "name": "$XSAPPNAME.user",
            "description": "Regular user access"
        },
        {
            "name": "$XSAPPNAME.admin",
            "description": "Administrator access"
        }
    ],
    "role-templates": [
        {
            "name": "User",
            "description": "Standard user",
            "scope-references": ["$XSAPPNAME.user"]
        },
        {
            "name": "Admin",
            "description": "Administrator",
            "scope-references": ["$XSAPPNAME.user", "$XSAPPNAME.admin"]
        }
    ],
    "role-collections": [
        {
            "name": "StudentManager_User",
            "description": "Student Manager Users",
            "role-template-references": ["$XSAPPNAME.User"]
        },
        {
            "name": "StudentManager_Admin",
            "description": "Student Manager Admins",
            "role-template-references": ["$XSAPPNAME.Admin"]
        }
    ],
    "oauth2-configuration": {
        "redirect-uris": ["https://*.cfapps.us10-001.hana.ondemand.com/**"],
        "token-validity": 900
    }
}
EOF
```

**🔍 Explain the XSUAA config:**

| Section | Purpose |
|---------|---------|
| `xsappname` | Unique application name in XSUAA — used as prefix for scopes |
| `tenant-mode: dedicated` | Single-tenant app (not shared across subaccounts) |
| `scopes` | Permissions that can be assigned. `$XSAPPNAME` is replaced at runtime with the actual app name |
| `role-templates` | Group scopes into roles. A `User` has basic access, `Admin` has both user + admin |
| `role-collections` | Assignable collections that BTP admins can give to users in the cockpit |
| `oauth2-configuration` | Redirect URIs for OAuth2 flow, token lifetime (900 seconds = 15 minutes) |

---

## Step 12 — Create & Explain mta.yaml

### 🎤 What to say

> "The `mta.yaml` is the deployment descriptor — it tells SAP BTP what modules to deploy, what services to create, and how they're connected. Think of it as a Docker Compose file for BTP."

### Command: Create `mta.yaml`

```bash
cat > mta.yaml << 'EOF'
_schema-version: "3.2"
ID: student-manager
version: 1.0.0
description: Student Manager - CAP Java Application

parameters:
  enable-parallel-deployments: true

# =============================================
# MODULES — things that get deployed (apps)
# =============================================
modules:

  # 1. Java Backend Service
  - name: student-manager-srv
    type: java
    path: srv
    parameters:
      memory: 1024M
      buildpack: sap_java_buildpack_jakarta
    properties:
      SPRING_PROFILES_ACTIVE: cloud
      JBP_CONFIG_COMPONENTS: "jres: ['com.sap.xs.java.buildpack.jre.SAPMachineJRE']"
      JBP_CONFIG_SAP_MACHINE_JRE: '{ version: 17.+ }'
    build-parameters:
      builder: custom
      commands:
        - mvn clean package -DskipTests
      build-result: target/*.jar
    provides:
      - name: srv-api
        properties:
          srv-url: ${default-url}
    requires:
      - name: student-manager-db
      - name: student-manager-xsuaa
      - name: student-manager-logging
      - name: student-manager-autoscaler

  # 2. HANA DB Deployer (runs once to create tables)
  - name: student-manager-db-deployer
    type: hdb
    path: db
    parameters:
      buildpack: nodejs_buildpack
    build-parameters:
      builder: custom
      commands:
        - npm install
    requires:
      - name: student-manager-db

  # 3. Application Router (entry point for users)
  - name: student-manager-approuter
    type: approuter.nodejs
    path: approuter
    parameters:
      memory: 256M
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

# =============================================
# RESOURCES — BTP services to create/bind
# =============================================
resources:

  # HANA HDI Container (database)
  - name: student-manager-db
    type: com.sap.xs.hdi-container
    parameters:
      service: hana
      service-plan: hdi-shared

  # XSUAA (OAuth2 authentication)
  - name: student-manager-xsuaa
    type: org.cloudfoundry.managed-service
    parameters:
      service: xsuaa
      service-plan: application
      path: xs-security.json

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
EOF
```

### Create the Approuter

```bash
mkdir -p approuter

cat > approuter/package.json << 'EOF'
{
    "name": "student-manager-approuter",
    "dependencies": {
        "@sap/approuter": "^16"
    },
    "scripts": {
        "start": "node node_modules/@sap/approuter/approuter.js"
    }
}
EOF

cat > approuter/xs-app.json << 'EOF'
{
    "welcomeFile": "/odata/v4/StudentService/$metadata",
    "authenticationMethod": "route",
    "routes": [
        {
            "source": "^/odata/(.*)$",
            "target": "/odata/$1",
            "destination": "student-manager-srv",
            "authenticationType": "xsuaa"
        },
        {
            "source": "^/actuator/(.*)$",
            "target": "/actuator/$1",
            "destination": "student-manager-srv",
            "authenticationType": "none"
        }
    ]
}
EOF
```

**🔍 Explain `mta.yaml` — The Big Picture:**

```
┌──────────────────────────────────────────────────────┐
│                   SAP BTP Cloud Foundry               │
│                                                        │
│  ┌─────────────────┐    ┌──────────────────────────┐  │
│  │   Approuter     │───▶│   Java Backend (srv)     │  │
│  │ (entry point)   │    │   Spring Boot + CAP      │  │
│  │ handles auth    │    │   OData V4 endpoints     │  │
│  └────────┬────────┘    └───────────┬──────────────┘  │
│           │                         │                  │
│           ▼                         ▼                  │
│  ┌─────────────────┐    ┌──────────────────────────┐  │
│  │     XSUAA       │    │      HANA Cloud          │  │
│  │  (OAuth2/JWT)   │    │   (HDI Container)        │  │
│  └─────────────────┘    └──────────────────────────┘  │
│                                                        │
│  ┌─────────────────┐    ┌──────────────────────────┐  │
│  │  App Logging    │    │     Autoscaler           │  │
│  └─────────────────┘    └──────────────────────────┘  │
└──────────────────────────────────────────────────────┘
```

### Explain each `mta.yaml` section:

#### Modules (what gets deployed)

| Module | Type | What it does |
|--------|------|-------------|
| `student-manager-srv` | `java` | Your Spring Boot app. Built with Maven, runs on SAP Java Buildpack with SAPMachine JRE 17 |
| `student-manager-db-deployer` | `hdb` | Runs **once** during deployment to create/update HANA tables via HDI. It's NOT a running app |
| `student-manager-approuter` | `approuter.nodejs` | SAP Application Router — the front door. Handles OAuth2 login flow, forwards requests to the Java backend |

#### Key properties explained

| Property | Meaning |
|----------|---------|
| `SPRING_PROFILES_ACTIVE: cloud` | Tells Spring Boot to use the `cloud` profile from `application.yaml` |
| `sap_java_buildpack_jakarta` | The SAP-optimized Java buildpack (Jakarta EE, SAPMachine JVM) |
| `provides: srv-api` | Makes the Java app's URL available to other modules |
| `requires: student-manager-xsuaa` | Binds the XSUAA service instance — injects credentials into `VCAP_SERVICES` |
| `forwardAuthToken: true` | Approuter forwards the JWT token to the Java backend |

#### Resources (BTP service instances)

| Resource | Service | Purpose |
|----------|---------|---------|
| `student-manager-db` | `hana` / `hdi-shared` | Creates an HDI container in HANA Cloud for your tables |
| `student-manager-xsuaa` | `xsuaa` / `application` | Creates an OAuth2 security service using `xs-security.json` |
| `student-manager-logging` | `application-logs` / `lite` | Collects application logs (viewable in BTP Cockpit) |
| `student-manager-autoscaler` | `autoscaler` / `standard` | Auto-scales your app based on CPU/memory usage |

---

## Step 13 — Configure Security (OAuth2 for Cloud, Basic for Local)

### 🎤 What to say

> "CAP has a dual security model: mock authentication for local development (so you don't need a real OAuth2 server), and XSUAA-based OAuth2 JWT validation in the cloud."

### How security works locally (already configured in Step 8)

In `application.yaml` under the `default` profile:

```yaml
cds:
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

**🔍 Explain:**
- **Mock security** creates fake users in memory — no external auth server needed
- You authenticate with **HTTP Basic Auth**: `admin/admin` or `user/user`
- Each mock user has assigned roles that match your CDS service annotations
- This is **ONLY active locally** — in the cloud, `mock.enabled` is not set, so it defaults to `false`

### How security works in the cloud

In `application.yaml` under the `cloud` profile:

```yaml
cds:
  security:
    xsuaa:
      enabled: true
```

**🔍 Explain the cloud authentication flow:**

```
1. User → Approuter
   ↓
2. Approuter redirects to XSUAA login page (SAP Identity Service)
   ↓
3. User logs in with SAP credentials
   ↓
4. XSUAA returns a JWT token to Approuter
   ↓
5. Approuter forwards request + JWT token → Java Backend
   ↓
6. CAP Java SDK validates the JWT token using XSUAA public keys
   ↓
7. CAP extracts roles from the JWT and enforces @requires annotations
```

### Restricting access in CDS

In `srv/service.cds`, the `@requires` annotation controls access:

```cds
// Only authenticated users can access this service
service StudentService @(requires: 'authenticated-user') {
    entity Students as projection on tutorial.Students;
}
```

You can also restrict individual entities:

```cds
service StudentService {
    // Anyone authenticated can read
    @(requires: 'authenticated-user')
    entity Students as projection on tutorial.Students;
    
    // Only admins can access settings (example)
    @(requires: 'admin')
    entity AdminSettings as projection on tutorial.AdminSettings;
}
```

### Testing security in Postman for cloud

To test the deployed app, you need a valid JWT token:

```bash
# 1. Get XSUAA credentials from BTP
cf env student-manager-srv | grep xsuaa

# 2. Request a token using client credentials
curl -X POST \
  https://<your-subdomain>.authentication.us10.hana.ondemand.com/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials&client_id=<client_id>&client_secret=<client_secret>"

# 3. Use the token in Postman
# Authorization tab → Bearer Token → paste the access_token
```

---

## Step 14 — Deploy to SAP BTP Trial

### 🎤 What to say

> "Now let's deploy everything to SAP BTP. We'll build an MTA archive and deploy it with the Cloud Foundry CLI."

### Step 14.1: Login to Cloud Foundry

```bash
# Login to SAP BTP Trial (US East region)
cf login -a https://api.cf.us10-001.hana.ondemand.com

# You'll be prompted for:
# - Email: your SAP trial email
# - Password: your SAP trial password
# - Org: select your trial org
# - Space: select 'dev'

# Verify login
cf target
```

### Step 14.2: Build the MTA archive

```bash
# Build the MTA archive (from project root)
mbt build

# This creates: mta_archives/student-manager_1.0.0.mtar
ls -la mta_archives/
```

**🔍 Explain what `mbt build` does:**
1. Reads `mta.yaml`
2. For `student-manager-srv`: runs `mvn clean package -DskipTests` → produces the JAR
3. For `student-manager-db-deployer`: runs `npm install` + `cds build --production` → produces HDI artifacts
4. For `student-manager-approuter`: packages the approuter
5. Bundles everything into a single `.mtar` archive

### Step 14.3: Deploy

```bash
# Deploy the MTA archive to BTP
cf deploy mta_archives/student-manager_1.0.0.mtar

# This will take 3-5 minutes. It will:
# 1. Create all service instances (HANA, XSUAA, Logging, Autoscaler)
# 2. Deploy the DB deployer (creates HANA tables)
# 3. Deploy the Java backend
# 4. Deploy the approuter
# 5. Bind services to apps
```

### Step 14.4: Verify deployment

```bash
# Check running apps
cf apps

# Expected output:
# name                         state     instances   memory   disk   urls
# student-manager-srv          started   1/1         1G       1G     student-manager-srv.cfapps.us10-001.hana.ondemand.com
# student-manager-approuter    started   1/1         256M     256M   student-manager-approuter.cfapps.us10-001.hana.ondemand.com

# Check services
cf services

# Expected output:
# name                        service            plan          bound apps
# student-manager-db          hana               hdi-shared    student-manager-srv, student-manager-db-deployer
# student-manager-xsuaa       xsuaa              application   student-manager-srv, student-manager-approuter
# student-manager-logging     application-logs   lite          student-manager-srv
# student-manager-autoscaler  autoscaler         standard      student-manager-srv

# Check logs
cf logs student-manager-srv --recent

# Test the deployed API (via approuter)
# Open in browser: https://student-manager-approuter.cfapps.us10-001.hana.ondemand.com/odata/v4/StudentService/$metadata
```

### Troubleshooting

```bash
# If app is not starting, check logs:
cf logs student-manager-srv --recent

# Check environment variables (VCAP_SERVICES):
cf env student-manager-srv

# Restart an app:
cf restart student-manager-srv

# Re-deploy only (without rebuilding):
cf deploy mta_archives/student-manager_1.0.0.mtar

# Undeploy everything:
cf undeploy student-manager --delete-services --delete-service-keys
```

---

## Step 15 — Explain Deployment & Runtime on BTP

### 🎤 What to say

> "Let's look at the BTP Cockpit and understand how everything is connected. I'll explain what happened during deployment and how requests flow through the system."

### How the app is deployed and running

```
┌─────────────────────────────────────────────────────────────┐
│                   SAP BTP Cockpit (Trial)                    │
│                                                              │
│  Subaccount: trial                                          │
│  └── Space: dev                                             │
│      │                                                      │
│      ├── Applications:                                      │
│      │   ├── student-manager-srv       (Java, running)      │
│      │   ├── student-manager-approuter (Node.js, running)   │
│      │   └── student-manager-db-deployer (stopped after deploy)│
│      │                                                      │
│      └── Service Instances:                                 │
│          ├── student-manager-db        (HANA HDI Container) │
│          ├── student-manager-xsuaa     (XSUAA OAuth2)       │
│          ├── student-manager-logging   (App Logging)        │
│          └── student-manager-autoscaler (Autoscaler)        │
└─────────────────────────────────────────────────────────────┘
```

### Request flow explained

```
User's Browser
    │
    ▼
┌─────────────────────────────────────────┐
│ 1. APPROUTER (student-manager-approuter) │
│    • Entry point for all requests        │
│    • Routes defined in xs-app.json       │
│    • Handles OAuth2 login via XSUAA      │
│    • Gets JWT token, forwards to backend │
└──────────────────┬──────────────────────┘
                   │ JWT token in Authorization header
                   ▼
┌─────────────────────────────────────────┐
│ 2. JAVA BACKEND (student-manager-srv)    │
│    • Spring Boot + CAP Java SDK          │
│    • Validates JWT token via XSUAA       │
│    • Processes OData request             │
│    • Runs event handlers (your code)     │
│    • Executes SQL against HANA           │
└──────────────────┬──────────────────────┘
                   │ SQL queries
                   ▼
┌─────────────────────────────────────────┐
│ 3. HANA CLOUD (HDI Container)            │
│    • Tables created by db-deployer       │
│    • Data persisted here                 │
│    • Supports OData queries natively     │
└─────────────────────────────────────────┘
```

### Security explained

```
┌──────────────────────────────────────────────────────────────┐
│                    Security Flow                              │
│                                                               │
│  1. User accesses approuter URL                              │
│     → Approuter checks: "Is there a valid session?"          │
│     → NO → Redirect to XSUAA login page                     │
│                                                               │
│  2. User logs in on XSUAA login page                         │
│     → XSUAA validates credentials against Identity Provider  │
│     → XSUAA issues JWT token containing:                     │
│       • User identity (name, email)                          │
│       • Scopes: ["student-manager!t123.user"]                │
│       • Expiry: 15 minutes (token-validity: 900)             │
│                                                               │
│  3. Approuter receives JWT, creates session                  │
│     → Forwards request to Java backend                       │
│     → Adds Authorization: Bearer <JWT> header                │
│                                                               │
│  4. Java backend validates JWT                               │
│     → Checks signature using XSUAA public key                │
│     → Extracts scopes → maps to CDS roles                   │
│     → @requires('authenticated-user') → checks if valid JWT  │
│     → If valid: process request                              │
│     → If invalid: return 401 Unauthorized                    │
│                                                               │
│  Role Assignment (BTP Cockpit):                              │
│  ┌───────────────┐  ┌─────────────────┐  ┌──────────────┐   │
│  │ BTP User      │──│ Role Collection  │──│ Role Template│   │
│  │ john@sap.com  │  │ StudentMgr_User │  │ User         │   │
│  └───────────────┘  └─────────────────┘  └──────┬───────┘   │
│                                                  │            │
│                                           ┌──────▼───────┐   │
│                                           │ Scope        │   │
│                                           │ $APP.user    │   │
│                                           └──────────────┘   │
└──────────────────────────────────────────────────────────────┘
```

### Key commands to show in BTP Cockpit

1. **Applications** → Show the running apps, their state, memory, instances
2. **Service Instances** → Show created services, bindings
3. **Security → Role Collections** → Show `StudentManager_User` and `StudentManager_Admin`
4. **Security → Role Collections → Assign User** → Demo assigning a user to a role collection
5. **Application Logs** → Show how to view logs from the Logging service

### Where to find your app URLs

```bash
# Get the approuter URL (this is what users access)
cf app student-manager-approuter | grep routes

# Get the backend URL (direct access, for testing)
cf app student-manager-srv | grep routes
```

---

## 📝 Summary & Key Takeaways

| What | Traditional Approach | CAP Approach |
|------|---------------------|-------------|
| Data Model | Java entities + JPA annotations | CDS model (`.cds` files) |
| API Layer | Spring Controllers + DTOs | Automatic OData V4 from CDS service |
| Database Schema | Liquibase / Flyway migrations | Auto-generated from CDS |
| CRUD Operations | Repositories + Service classes | Free with CDS projections |
| Security | Spring Security config | `@requires` annotation in CDS |
| Deployment | Dockerfile + CI/CD | `mta.yaml` + `cf deploy` |
| Cloud Services | Manual service binding | Declarative in `mta.yaml` resources |

### CAP Philosophy

1. **Focus on the domain** — define your data model and business logic, not boilerplate
2. **Best practices built-in** — OData compliance, security, multi-tenancy out of the box
3. **Local = Cloud parity** — same code runs locally (H2 + mock auth) and on BTP (HANA + XSUAA)
4. **Convention over configuration** — sensible defaults, override when needed

---

## 🔗 Useful Links

- [CAP Java Documentation](https://cap.cloud.sap/docs/java/)
- [CDS Language Reference](https://cap.cloud.sap/docs/cds/)
- [SAP BTP Trial Account](https://account.hanatrial.ondemand.com/)
- [CAP Samples on GitHub](https://github.com/SAP-samples/cloud-cap-samples-java)
- [OData V4 Specification](https://www.odata.org/documentation/)