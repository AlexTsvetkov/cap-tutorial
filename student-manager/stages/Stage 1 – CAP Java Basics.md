# Stage 1 – CAP Java Basics

> **Estimated Duration:** 1-2 weeks  
> **Prerequisites:** Java 21, Node.js 18+, Maven 3.8+, CF CLI  
> **Reference:** [steps.md](../steps.md), [presentation_script.md](../presentation_script.md)

## Overview

Build and deploy a **Student Manager** application using SAP CAP Java SDK with OData V4 API, H2 database for local development, and HANA Cloud for production.

---

## Functional Requirements [FR]

* Create a CAP Java project with Spring Boot using Maven archetype
* Implement **Students** entity with full CRUD operations via OData V4
* Add custom validation handler (email validation)
* Configure dual security: Basic Auth (local) / XSUAA (cloud)
* Deploy to SAP BTP Cloud Foundry with HANA Cloud database

---

## Steps

### Local Development

1. **[SETUP] Install Prerequisites**
   - Install @sap/cds-dk, mbt, CF CLI with multiapps plugin
   - Verify Java 21 is installed (required for cloud!)

2. **[CAP] Scaffold CAP Java Project**
   - Use `cds-services-archetype` Maven archetype
   - Run `npm install` to install CDS dependencies

3. **[CDS] Define Data Model**
   - Create `db/schema.cds` with Students entity
   - Use `cuid` and `managed` aspects from @sap/cds/common

4. **[CDS] Define Service**
   - Create `srv/service.cds` exposing Students as projection
   - CAP provides automatic CRUD operations

5. **[JAVA] Add Custom Handler**
   - Create `StudentServiceHandler.java` with `@Before` event handler
   - Implement email validation using `ServiceException`

6. **[SPRING] Configure Application**
   - Create `application.yaml` with profiles: default (H2) and cloud (HANA)
   - Configure H2 console, actuator endpoints

7. **[SPRING] Configure Security**
   - Create `SecurityConfig.java` with dual configuration
   - Local: Basic Auth with mock users (admin/admin)
   - Public actuator endpoints for health checks

8. **[TEST] Run and Test Locally**
   - Run `mvn spring-boot:run` from srv folder
   - Test OData endpoints with Postman using Basic Auth

### Cloud Deployment

9. **[DEPS] Add Cloud Dependencies**
    - Add `cds-feature-hana`, `cds-starter-cloudfoundry`, `spring-boot-starter-actuator`

10. **[NPM] Configure package.json**
    - Add npm scripts: `build:mta`, `deploy`
    - Configure CDS requires for production (hana, xsuaa)

11. **[HDI] Configure db/package.json**
    - Add `@sap/hdi-deploy` and `hdb` dependencies
    - ⚠️ `hdb` is required for database connectivity!

12. **[XSUAA] Create xs-security.json**
    - Define scopes, role-templates, role-collections

13. **[MTA] Create mta.yaml**
    - Configure Java module with `sap_java_buildpack_jakarta`
    - ⚠️ Must specify Java 21: `JBP_CONFIG_SAP_MACHINE_JRE: '{ version: 21.+ }'`
    - Configure DB deployer and resources (hdi-container, xsuaa)

14. **[HANA] Create HANA Cloud Instance**
    - ⚠️ **CRITICAL:** Must create HANA Cloud instance BEFORE deployment!
    - Use BTP Cockpit or CF CLI to create `hana-cloud` service with `hana-free` plan
    - Wait 10-20 minutes for "Running" status

15. **[BUILD] Build MTA Archive**
    - ⚠️ **CRITICAL:** Must run `cds build --for hana` before MTA build!
    - Use `npm run build:mta` which runs both commands

16. **[DEPLOY] Deploy to Cloud Foundry**
    - Login with `cf login`
    - Deploy with `cf deploy mta_archives/student-manager_1.0.0.mtar`

17. **[VERIFY] Verify Deployment**
    - Check apps with `cf apps`
    - Check logs with `cf logs student-manager-srv --recent`
    - Test OData endpoint with OAuth2 token

---

## Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| "Table not found" 500 error | Missing HANA artifacts | Run `cds build --for hana` |
| "Could not create service db" | No HANA Cloud instance | Create HANA instance first |
| "UnsupportedClassVersionError" | Java version mismatch | Set Java 21 in mta.yaml |
| "requires hdb peer dependency" | Missing hdb in db/package.json | Add `hdb` dependency |

---

## Achievements

| Concept | Description |
|---------|-------------|
| CDS Data Model | Declarative entity definitions with aspects |
| CDS Service | OData V4 service with projections |
| Generic Handlers | Automatic CRUD operations |
| Custom Handler | Java `@Before` event handler |
| HDI Container | HANA Deployment Infrastructure |
| MTA Deployment | Multi-Target Application packaging |
| Dual Security | Basic Auth (local) / XSUAA (cloud) |

---

## Quick Reference

```bash
# Local
cd srv && mvn spring-boot:run

# Cloud
npm run build:mta
npm run deploy
cf logs student-manager-srv --recent