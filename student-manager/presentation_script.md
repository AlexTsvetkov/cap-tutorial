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
8. [Configure application.yaml (Local Development)](#step-8--configure-applicationyaml-local-development)
9. [Build the App & Explore Generated Files](#step-9--build-the-app--explore-generated-files)
10. [Run Locally & Test with Postman](#step-10--run-locally--test-with-postman)
11. [Add BTP Services (HANA, XSUAA, Logging, Autoscaler)](#step-11--add-btp-services-hana-xsuaa-logging-autoscaler)
12. [Create & Explain mta.yaml](#step-12--create--explain-mtayaml)
13. [Configure Cloud Profile & Security](#step-13--configure-cloud-profile--security)
14. [Create HANA Cloud Instance (Required!)](#step-14--create-hana-cloud-instance-required)
15. [Build & Deploy to SAP BTP Trial](#step-15--build--deploy-to-sap-btp-trial)
16. [Explain Deployment & Runtime on BTP](#step-16--explain-deployment--runtime-on-btp)
17. [Troubleshooting Common Issues](#step-17--troubleshooting-common-issues)

---

## Step 1 — Prerequisites & Tool Installation

### 🎤 What to say

> "Before we start coding, let's make sure we have all required tools installed. CAP Java projects need Node.js for the CDS compiler, Java + Maven for the backend, and the Cloud Foundry CLI for deployment."

### Required tools

| Tool | Purpose | Verify command |
|------|---------|---------------|
| **Node.js** (≥18) | CDS compiler, npm packages | `node -v` |
| **Java JDK 21** | Java backend runtime (required for cloud!) | `java -version` |
| **Maven** (3.8+) | Build tool for Java | `mvn -version` |
| **@sap/cds-dk** | CDS development kit (CLI) | `cds version` |
| **Cloud Foundry CLI** | Deploy to SAP BTP | `cf version` |
| **MBT (MTA Build Tool)** | Build MTA archives for deployment | `mbt --version` |

> ⚠️ **IMPORTANT:** Java 21 is required for SAP BTP Cloud Foundry deployment. Java 17 will cause `UnsupportedClassVersionError` errors in the cloud.

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
        <java.version>21</java.version>                           <!-- ② Java 21 required! -->
        <cds.services.version>3.7.0</cds.services.version>        <!-- ③ CAP SDK version -->
        <spring.boot.version>3.4.1</spring.boot.version>          <!-- ④ Spring Boot version -->
    </properties>

    <modules>
        <module>srv</module>                   <!-- ⑤ Child module: service -->
    </modules>

    <dependencyManagement>
        <dependencies>
            <!-- ⑥ CAP Java SDK BOM — manages all CAP dependency versions -->
            <dependency>
                <groupId>com.sap.cds</groupId>
                <artifactId>cds-services-bom</artifactId>
                <version>${cds.services.version}</version>
                <type>pom</type>
                <scope>import</scope>
            </dependency>

            <!-- ⑦ Spring Boot BOM — manages all Spring dependency versions -->
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
| ② | `java.version: 21` | **Java 21 is required** for SAP BTP deployment. The cloud runtime uses Java 21 |
| ③ | `cds.services.version` | The version of the CAP Java SDK. All CAP dependencies use this version |
| ④ | `spring.boot.version` | CAP Java is built on top of Spring Boot |
| ⑤ | `<modules>` | Lists child modules. Maven builds them in order |
| ⑥ | `cds-services-bom` | **Bill of Materials** — imports all CAP Java SDK dependency versions |
| ⑦ | `spring-boot-dependencies` | Same idea — imports all Spring Boot managed versions |

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
| `cds-starter-spring-boot` | The **main starter** — bootstraps the CAP Java runtime on top of Spring Boot |
| `cds-adapter-odata-v4` | Translates CDS service definitions into **OData V4 endpoints** automatically |
| `h2` | Lightweight in-memory SQL database for **local development** |

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
2. **Generates Java interfaces** from your CDS entities and services

> ⚠️ **IMPORTANT:** The CDS Maven plugin only runs `cds build --for java`. It does **NOT** generate HANA database artifacts. We'll explain this later in deployment.

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
| `entity Students as projection on tutorial.Students` | **Exposes** the `Students` entity through this service |

> 💡 **Key takeaway:** This is ALL you need for a fully functional REST/OData API! CAP automatically provides:
> - `GET /odata/v4/StudentService/Students` — Read all
> - `GET /odata/v4/StudentService/Students({id})` — Read by ID
> - `POST /odata/v4/StudentService/Students` — Create
> - `PATCH /odata/v4/StudentService/Students({id})` — Update
> - `DELETE /odata/v4/StudentService/Students({id})` — Delete
> - Full OData query support: `$filter`, `$select`, `$orderby`, `$top`, `$skip`, `$count`

### Optional: Add a Custom Event Handler (Email Validation)

If you want to add custom business logic (e.g., validation), create a Java handler:

```bash
mkdir -p srv/src/main/java/com/tutorial/studentmanager/handlers

cat > srv/src/main/java/com/tutorial/studentmanager/handlers/StudentServiceHandler.java << 'EOF'
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

@Component
@ServiceName("StudentService")
public class StudentServiceHandler implements EventHandler {

    /**
     * Validation: runs BEFORE every CREATE or UPDATE operation on Students.
     * Ensures email contains '@' character.
     */
    @Before(event = {CdsService.EVENT_CREATE, CdsService.EVENT_UPDATE}, entity = Students_.CDS_NAME)
    public void validateEmail(Students student) {
        String email = student.getEmail();
        if (email != null && !email.contains("@")) {
            throw new ServiceException(
                ErrorStatuses.BAD_REQUEST,
                "Invalid email format: " + email + ". Email must contain '@' character."
            );
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
| `@Before(event = ...)` | This method runs **before** the specified events |
| `entity = Students_.CDS_NAME` | Only for the Students entity |
| `ServiceException` | CAP's exception class with proper HTTP status codes |

---

## Step 7 — Add Initial Data

### 🎤 What to say

> "Let's add some test data so we have something to see when we run the app. For local development with H2, we use SQL scripts that Spring Boot auto-executes on startup."

### Command: Create initial data SQL

```bash
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
- **In production (HANA):** data is persisted, not loaded from SQL scripts

---

## Step 8 — Configure application.yaml (Local Development)

### 🎤 What to say

> "The `application.yaml` is where we configure Spring Boot + CAP behavior. For now, we'll set up the local development profile with H2 in-memory database. Later, when we prepare for cloud deployment, we'll add a cloud profile."

### Command: Create application.yaml

```bash
cat > srv/src/main/resources/application.yaml << 'YAML'
spring:
  application:
    name: student-manager
  profiles:
    active: default

# =============================================
# LOCAL profile (default) — H2 in-memory database
# =============================================
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
  odata-v4.endpoint.path: /odata/v4

management:
  endpoints:
    web:
      exposure:
        include: health,info
  endpoint:
    health:
      show-details: always
YAML
```

**🔍 Explain section by section:**

### Global settings
| Setting | Purpose |
|---------|---------|
| `spring.application.name` | Names our Spring Boot application |
| `spring.profiles.active: default` | Activates the `default` profile — used for local development |

### Local profile (`default`)
| Setting | Purpose |
|---------|---------|
| `spring.datasource.url` | H2 in-memory database — data is lost on restart |
| `spring.sql.init.mode: always` | Runs `data.sql` every startup to seed test data |
| `h2.console.enabled: true` | H2 web console at `/h2-console` for debugging |
| `cds.odata-v4.endpoint.path` | Sets the OData V4 endpoint base path |
| `management.endpoints` | Exposes health and info actuator endpoints |

> 💡 **Note:** We'll add a `cloud` profile in Step 13 when we configure security and cloud-specific settings.

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
# - cds/gen/studentservice/Students.java      ← Java interface for the entity
# - cds/gen/studentservice/Students_.java     ← Static metadata class
# - cds/gen/studentservice/StudentService.java ← Service interface
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

> 💡 These generated interfaces give you **type-safe access** to CDS entities in Java code.

```bash
# 2. Generated CSN (Core Schema Notation) — the compiled CDS model
cat srv/src/main/resources/edmx/csn.json | head -50

# 3. Generated OData EDMX metadata
cat srv/src/main/resources/edmx/odata/v4/StudentService.xml
```

---

## Step 10 — Run Locally & Test with Postman

### 🎤 What to say

> "Let's start the application and see our OData API in action. We'll test CRUD operations using Postman and explore OData query capabilities."

### Command: Run the app

```bash
# Run with Maven Spring Boot plugin
cd srv && mvn spring-boot:run
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

#### 2. Read all Students

```
GET http://localhost:8080/odata/v4/StudentService/Students
Authorization: Basic admin:admin
```

#### 3. OData query examples

```bash
# $filter — server-side filtering
GET .../Students?$filter=status eq 'ACTIVE'

# $select — only return specific fields
GET .../Students?$select=firstName,lastName,email

# $orderby — sorting
GET .../Students?$orderby=lastName asc

# $top and $skip — pagination
GET .../Students?$top=10&$skip=0
```

#### 4. Create a new Student

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

#### 5. Update a Student (PATCH)

```
PATCH http://localhost:8080/odata/v4/StudentService/Students(11111111-1111-1111-1111-111111111111)
Authorization: Basic admin:admin
Content-Type: application/json

{
    "status": "GRADUATED"
}
```

#### 6. Delete a Student

```
DELETE http://localhost:8080/odata/v4/StudentService/Students(33333333-3333-3333-3333-333333333333)
Authorization: Basic admin:admin
```

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
    <scope>runtime</scope>
</dependency>

<!-- Cloud Foundry integration — reads VCAP_SERVICES, enables XSUAA -->
<dependency>
    <groupId>com.sap.cds</groupId>
    <artifactId>cds-starter-cloudfoundry</artifactId>
</dependency>

<!-- Spring Boot Actuator — health checks used by BTP -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
```

### Step 11.2: Configure `package.json` for production

```bash
cat > package.json << 'EOF'
{
    "name": "student-manager",
    "version": "1.0.0",
    "private": true,
    "dependencies": {
        "@sap/cds": "^8",
        "express": "^4"
    },
    "devDependencies": {
        "@sap/cds-dk": "^8"
    },
    "scripts": {
        "build": "cds build --production",
        "build:hana": "cds build --for hana",
        "build:java": "cds build --for java",
        "build:all": "cds build --for hana && cd srv && mvn clean package -DskipTests",
        "build:mta": "cds build --for hana && mbt build -t mta_archives/",
        "deploy": "cf deploy mta_archives/student-manager_1.0.0.mtar"
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

**🔍 Explain the npm scripts:**

| Script | Purpose |
|--------|---------|
| `build:hana` | Generates HANA artifacts (`.hdbtable`, `.hdbview`) in `db/src/gen/` |
| `build:java` | Generates Java artifacts — same as `mvn compile` |
| `build:mta` | **Full cloud build:** generates HANA artifacts + builds MTA archive |
| `deploy` | Deploys the MTA archive to Cloud Foundry |

> ⚠️ **CRITICAL:** `mvn clean package` does NOT generate HANA artifacts! You must run `cds build --for hana` before building the MTA!

### Step 11.3: Configure `db/package.json` for HDI deployer

> ⚠️ **IMPORTANT:** Must include `hdb` dependency for database connectivity!

```bash
cat > db/package.json << 'EOF'
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
EOF

# Install dependencies
cd db && npm install && cd ..
```

### Step 11.4: Create `xs-security.json` (XSUAA Configuration)

```bash
cat > xs-security.json << 'EOF'
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
EOF
```

---

## Step 12 — Create & Explain mta.yaml

### 🎤 What to say

> "The `mta.yaml` is the deployment descriptor — it tells SAP BTP what modules to deploy, what services to create, and how they're connected."

### Command: Create `mta.yaml`

```bash
cat > mta.yaml << 'EOF'
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
EOF
```

> ⚠️ **IMPORTANT:** Notice `JBP_CONFIG_SAP_MACHINE_JRE: '{ version: 21.+ }'` — this ensures Java 21 runtime in the cloud!

### Create the Approuter

```bash
mkdir -p approuter

cat > approuter/package.json << 'EOF'
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
EOF

cat > approuter/xs-app.json << 'EOF'
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
EOF
```

---

## Step 13 — Configure Cloud Profile & Security

### 🎤 What to say

> "Now that we have the MTA descriptor and BTP services configured, we need to do two things: add a `cloud` profile to our `application.yaml` for HANA and XSUAA settings, and create a Spring Security configuration that handles both local and cloud authentication."

### Step 13.1: Add Cloud Profile to application.yaml

> "Remember in Step 8, we only configured the `default` (local) profile. Now we need to add a `cloud` profile that tells CAP how to connect to HANA and use XSUAA for authentication when running on SAP BTP."

Append the cloud profile to the existing `application.yaml`:

```bash
cat >> srv/src/main/resources/application.yaml << 'YAML'

# =============================================
# CLOUD profile — SAP BTP Cloud Foundry
# =============================================
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

management:
  endpoints:
    web:
      exposure:
        include: health,info
  endpoint:
    health:
      probes:
        enabled: true
      show-details: always
YAML
```

**🔍 Explain the cloud profile:**

| Setting | Purpose |
|---------|---------|
| `on-profile: cloud` | Activated when `SPRING_PROFILES_ACTIVE=cloud` is set (configured in `mta.yaml`) |
| `sql.init.mode: never` | Don't run SQL init scripts in cloud — HANA has its own data managed by the HDI deployer |
| `cds.datasource.auto-config` | CAP automatically reads `VCAP_SERVICES` environment variable to connect to the HANA HDI container |
| `cds.security.xsuaa.enabled` | Enables **real OAuth2 JWT token validation** using the XSUAA service instance |
| `health.probes.enabled` | Enables Kubernetes-style liveness/readiness probes used by Cloud Foundry |

> 💡 **How Spring profiles work:** When deployed to BTP, the `mta.yaml` sets `SPRING_PROFILES_ACTIVE=cloud` as an environment variable. Spring Boot then loads the `cloud` profile settings **on top of** the global settings, overriding any conflicting values from the `default` profile.

### Step 13.2: Create Spring Security Configuration

```bash
mkdir -p srv/src/main/java/com/tutorial/studentmanager/config

cat > srv/src/main/java/com/tutorial/studentmanager/config/SecurityConfig.java << 'EOF'
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

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    @Order(1)
    public SecurityFilterChain actuatorSecurityFilterChain(HttpSecurity http) throws Exception {
        http
            .securityMatcher("/actuator/**")
            .authorizeHttpRequests(authorize -> authorize
                .anyRequest().permitAll()
            );
        return http.build();
    }

    @Bean
    @Order(2)
    @Profile("default")
    public SecurityFilterChain defaultSecurityFilterChain(HttpSecurity http) throws Exception {
        http
            .csrf(csrf -> csrf.disable())
            .authorizeHttpRequests(authorize -> authorize
                .requestMatchers("/h2-console/**").permitAll()
                .anyRequest().authenticated()
            )
            .headers(headers -> headers.frameOptions(frame -> frame.disable()))
            .httpBasic(basic -> {});
        return http.build();
    }

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
EOF
```

**🔍 Explain:**
- **Order 1 (Actuator):** Health endpoints are public (required for BTP health checks)
- **Order 2 (Default profile):** Local dev uses Basic Auth with mock users `admin/admin` and `user/user`
- **Cloud profile:** No custom config needed — CAP auto-configures XSUAA JWT validation

---

## Step 14 — Create HANA Cloud Instance (Required!)

### 🎤 What to say

> "⚠️ **CRITICAL STEP!** Before we can deploy, we MUST create a SAP HANA Cloud instance. The HDI container service we're using requires an existing HANA Cloud database. This is NOT auto-created during deployment!"

### Option A: Via BTP Cockpit (Recommended for demos)

1. Go to [SAP BTP Cockpit](https://cockpit.hanatrial.ondemand.com/)
2. Navigate to your **Subaccount** → **Service Marketplace**
3. Search for **"SAP HANA Cloud"**
4. Click **Create** → Select plan: **`hana-free`** (for trial)
5. Configure:
   - **Instance Name:** `student-manager-hana`
   - **Administrator Password:** Set a secure password
   - **Allowed Connections:** "Allow all IP addresses" (for trial)
6. Click **Create**
7. **⏳ Wait 10-20 minutes** for the instance to reach "Running" state

### Option B: Via CF CLI

Create `hana-cloud-config.json`:
```bash
cat > hana-cloud-config.json << 'EOF'
{
    "data": {
        "memory": 16,
        "systempassword": "YourSecurePassword123!",
        "edition": "cloud",
        "vcpu": 1,
        "whitelistIPs": ["0.0.0.0/0"]
    }
}
EOF
```

```bash
# Create HANA Cloud instance
cf create-service hana-cloud hana-free student-manager-hana -c hana-cloud-config.json
```

### Verify HANA is Running

```bash
cf services
# Should show: student-manager-hana  hana-cloud  hana-free  create succeeded
```

> ⚠️ **Trial accounts:** HANA Cloud instances auto-stop after periods of inactivity. You may need to restart them before each development session via the SAP HANA Cloud Central dashboard.

---

## Step 15 — Build & Deploy to SAP BTP Trial

### 🎤 What to say

> "Now let's deploy everything to SAP BTP. But first, let me explain a critical concept about CDS build tasks that many people miss."

### Understanding CDS Build Tasks (⚠️ Important!)

```
┌─────────────────────────────────────────────────────────────┐
│                  CDS Build Tasks                             │
├─────────────────────────────────────────────────────────────┤
│  Command                │ Output              │ Purpose      │
│─────────────────────────│─────────────────────│──────────────│
│  cds build --for java   │ srv/src/main/       │ Java runtime │
│                         │ resources/edmx/     │ (OData meta) │
│─────────────────────────│─────────────────────│──────────────│
│  cds build --for hana   │ db/src/gen/         │ HANA tables  │
│                         │ *.hdbtable,hdbview  │ (HDI deploy) │
└─────────────────────────────────────────────────────────────┘

⚠️ mvn clean package only runs "cds build --for java"
   It does NOT generate HANA artifacts!
```

**🔍 Explain:**
- The CDS Maven plugin runs `cds build --for java` during Maven compile
- But the **HANA artifacts** (`db/src/gen/*.hdbtable`) are **NOT generated** by Maven
- These are needed by the HDI deployer to create tables in HANA
- You must run `cds build --for hana` manually before building the MTA!

### Step 15.1: Login to Cloud Foundry

```bash
cf login -a https://api.cf.us10-001.hana.ondemand.com
# Enter your email and password when prompted
```

### Step 15.2: Build the MTA Archive

> ⚠️ **Use the npm script that runs both builds!**

```bash
# Option A: Use npm script (RECOMMENDED!)
npm run build:mta

# Option B: Manual commands
cds build --for hana    # Generate db/src/gen/*.hdbtable, *.hdbview
mbt build               # Build MTA archive (includes mvn package)

# Verify artifacts were created
ls -la db/src/gen/
# Should see: tutorial-Students.hdbtable, etc.

ls -la mta_archives/
# Should see: student-manager_1.0.0.mtar
```

### Step 15.3: Deploy

```bash
cf deploy mta_archives/student-manager_1.0.0.mtar
```

This will take 3-5 minutes. It will:
1. Create all service instances (HANA HDI, XSUAA, Logging, Autoscaler)
2. Deploy the DB deployer (creates HANA tables)
3. Deploy the Java backend
4. Deploy the approuter
5. Bind services to apps

### Step 15.4: Verify Deployment

```bash
# Check running apps
cf apps

# Check services
cf services

# Check logs if something went wrong
cf logs student-manager-srv --recent
```

---

## Step 16 — Explain Deployment & Runtime on BTP

### 🎤 What to say

> "Let's look at the BTP Cockpit and understand how everything is connected."

### How the app is deployed and running

```
┌─────────────────────────────────────────────────────────────┐
│                   SAP BTP Cloud Foundry                      │
│                                                              │
│  ┌─────────────────┐    ┌──────────────────────────┐        │
│  │   Approuter     │───▶│   Java Backend (srv)     │        │
│  │ (entry point)   │    │   Spring Boot + CAP      │        │
│  │ handles auth    │    │   OData V4 endpoints     │        │
│  └────────┬────────┘    └───────────┬──────────────┘        │
│           │                         │                        │
│           ▼                         ▼                        │
│  ┌─────────────────┐    ┌──────────────────────────┐        │
│  │     XSUAA       │    │      HANA Cloud          │        │
│  │  (OAuth2/JWT)   │    │   (HDI Container)        │        │
│  └─────────────────┘    └──────────────────────────┘        │
└─────────────────────────────────────────────────────────────┘
```

### Testing in the Cloud

```bash
# Get XSUAA credentials for API testing
cf env student-manager-srv | grep -A 50 xsuaa

# Request a token
curl -X POST "<xsuaa-url>/oauth/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials&client_id=<clientid>&client_secret=<clientsecret>"

# Use the token to call the API
curl -H "Authorization: Bearer <token>" \
  https://<your-app-url>/odata/v4/StudentService/Students
```

---

## Step 17 — Troubleshooting Common Issues

### 🎤 What to say

> "Let me show you some common issues you might encounter and how to fix them."

### Error: "Table TUTORIAL_STUDENTS not found" (500 Error)

**Cause**: HANA artifacts not deployed. Missing `db/src/gen/` folder.

**Error message:**
```
CdsDataException: Target 'StudentService.Students' does not exist as table or view
```

**Solution**:
```bash
# Generate HANA artifacts
cds build --for hana

# Rebuild and redeploy
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
4. Wait for "Running" status
5. Retry deployment

### Error: "UnsupportedClassVersionError" (Java 65.0 vs 61.0)

**Cause**: App compiled with Java 21, runtime using Java 17.

**Error message:**
```
UnsupportedClassVersionError: com/tutorial/studentmanager/Application 
has been compiled by a more recent version of the Java Runtime 
(class file version 65.0), this version only recognizes up to 61.0
```

**Solution**: Ensure `mta.yaml` has:
```yaml
properties:
  JBP_CONFIG_SAP_MACHINE_JRE: '{ version: 21.+ }'
```

### Error: "requires a peer of '@sap/hana-client' or 'hdb'"

**Cause**: Missing database client in `db/package.json`.

**Solution**: Add `"hdb": "^0.19.0"` to dependencies:
```bash
cd db
npm install hdb
cd ..
```

Then rebuild and redeploy.

---

## 📝 Summary & Key Takeaways

| What | Traditional Approach | CAP Approach |
|------|---------------------|-------------|
| Data Model | Java entities + JPA | CDS model (`.cds` files) |
| API Layer | Spring Controllers | Automatic OData V4 |
| Database Schema | Liquibase / Flyway | Auto-generated from CDS |
| CRUD Operations | Repositories + Services | Free with CDS |
| Deployment | Dockerfile + CI/CD | `mta.yaml` + `cf deploy` |

### Critical Build Commands

```bash
# Local development
cd srv && mvn spring-boot:run

# Cloud deployment (MUST include cds build --for hana!)
npm run build:mta
cf deploy mta_archives/student-manager_1.0.0.mtar
```

### CAP Philosophy

1. **Focus on the domain** — define your data model and business logic, not boilerplate
2. **Best practices built-in** — OData compliance, security, multi-tenancy out of the box
3. **Local = Cloud parity** — same code runs locally (H2 + mock auth) and on BTP (HANA + XSUAA)

---

## 🔗 Useful Links

- [CAP Java Documentation](https://cap.cloud.sap/docs/java/)
- [CDS Language Reference](https://cap.cloud.sap/docs/cds/)
- [SAP BTP Trial Account](https://account.hanatrial.ondemand.com/)
- [CAP Samples on GitHub](https://github.com/SAP-samples/cloud-cap-samples-java)