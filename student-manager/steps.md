# CAP Java Student Manager - Step-by-Step Implementation

## Step 1 - Prerequisites & Tool Installation

Required tools:
- Node.js (≥18): `node -v`
- Java JDK (17+): `java -version`
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
3. Update `.gitignore` for CAP Java

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

- `student-manager/db/schema.cds` - Students entity with cuid, managed aspects

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

## Step 6 - Service & Handler

- `student-manager/srv/service.cds` - StudentService exposing Students entity

```cds
using { tutorial } from '../db/schema';

service StudentService {
    entity Students as projection on tutorial.Students;
}
```

- `student-manager/srv/src/main/java/com/tutorial/studentmanager/handlers/StudentServiceHandler.java` - Email validation handler

---

## Step 7 - Initial Data

- `student-manager/srv/src/main/resources/data.sql` - 3 test student records

---

## Step 8 - Configuration

- `student-manager/srv/src/main/resources/application.yaml` - Full config with default (H2) and cloud (HANA/XSUAA) profiles

---

## Step 9 - Build & Explore Generated Files

```bash
mvn clean compile
```

Generated files:
- `srv/src/gen/java/` - Java interfaces from CDS models
- `srv/src/main/resources/edmx/csn.json` - Compiled CDS model
- `srv/src/main/resources/edmx/odata/v4/StudentService.xml` - OData EDMX metadata

---

## Step 10 - Run Locally & Test

```bash
mvn -pl srv spring-boot:run
```

Test endpoints:
- `GET http://localhost:8080/odata/v4/StudentService/$metadata`
- `GET http://localhost:8080/odata/v4/StudentService/Students`
- Use Basic Auth: `admin/admin` or `user/user`

---

## Step 11 - BTP Services

- `student-manager/srv/pom.xml` - Added cds-feature-hana, cds-starter-cloudfoundry, spring-boot-starter-actuator
- `student-manager/package.json` - Updated with CDS production config

---

## Step 12 - Deployment Descriptors

- `student-manager/xs-security.json` - XSUAA configuration with roles and role collections
- `student-manager/mta.yaml` - MTA deployment descriptor with srv, db-deployer, approuter modules and HANA/XSUAA/Logging/Autoscaler resources
- `student-manager/approuter/package.json` - Approuter dependencies
- `student-manager/approuter/xs-app.json` - Routing configuration
- `student-manager/db/package.json` - HDI deployer dependencies

---

## Step 13 - Security Configuration

Already configured in Step 8:
- Local: Mock users with Basic Auth
- Cloud: XSUAA OAuth2 JWT tokens

---

## Step 14 - Deploy to SAP BTP

```bash
cf login -a https://api.cf.us10-001.hana.ondemand.com
mbt build
cf deploy mta_archives/student-manager_1.0.0.mtar
```

---

## Step 15 - Verify Deployment

```bash
cf apps
cf services
cf logs student-manager-srv --recent