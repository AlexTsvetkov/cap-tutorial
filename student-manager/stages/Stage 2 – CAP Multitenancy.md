# Stage 2 – CAP Multitenancy

> **Estimated Duration:** 2-3 weeks  
> **Prerequisites:** Stage 1 (CAP Java Basics), understanding of multitenancy concepts  
> **Reference:** [CAP Multitenancy Documentation](https://cap.cloud.sap/docs/guides/multitenancy/)

## Overview

Add **multitenancy support** to your CAP Java application with **schema-per-tenant** isolation. CAP provides built-in multitenancy features making implementation significantly simpler than manual approaches.

Key CAP multitenancy features:
- **Automatic tenant isolation** at the database level (HDI container per tenant)
- **Built-in SaaS subscription callbacks**
- **Tenant-aware dependency injection**
- **MTX (Multitenancy Extension) services**

---

## Functional Requirements [FR]

* Enable multitenancy in CAP project configuration
* Configure SaaS Registry for tenant subscription management
* Update xs-security.json with `tenant-mode: shared`
* Add Approuter for tenant-specific URL routing
* Configure Service Manager for tenant database provisioning
* Test subscription/unsubscription flows

---

## Required Services (Updated)

| Service | Plan | Purpose |
|---------|------|---------|
| XSUAA | **broker** | OAuth 2.0 with tenant-shared mode |
| Service Manager | **container** | Dynamic HDI container per tenant |
| SaaS Registry | **application** | Marketplace & subscription management |
| HANA Cloud | hdi-shared | Provider database (via Service Manager) |

---

## Steps

### Configuration

1. **[CDS] Enable Multitenancy in package.json**
   - Set `"multitenancy": true` in cds.requires
   - Enable `toggles` and `extensibility` options
   - Keep production db/auth configuration

2. **[SPRING] Update application.yaml**
   - Enable `cds.multitenancy.enabled: true`
   - Enable `cds.multitenancy.mtxs.enabled: true`
   - Configure subscription scope for callbacks

3. **[XSUAA] Update xs-security.json**
   - Change `tenant-mode` from `dedicated` to `shared`
   - Add `mtcallback` scope for subscription callbacks
   - Add `mtdeployment` scope for HDI deployment
   - Grant scopes to sap-provisioning and broker apps

### Approuter

4. **[APPROUTER] Create Approuter Module**
   - Create `approuter/package.json` with @sap/approuter dependency
   - Create `approuter/xs-app.json` with routes to backend

5. **[APPROUTER] Configure Tenant URL Pattern**
   - Set `TENANT_HOST_PATTERN` for tenant-specific URLs
   - Format: `^(.*)-<app>-approuter.cfapps.<region>.hana.ondemand.com`

### MTA Configuration

6. **[MTA] Update mta.yaml for Multitenancy**
   - Add Approuter module with TENANT_HOST_PATTERN
   - Change XSUAA plan from `application` to `broker`
   - Add Service Manager resource with `container` plan
   - Add SaaS Registry resource with subscription URLs:
     - `getDependencies`: `~{srv-url}/-/cds/saas-provisioning/dependencies`
     - `onSubscription`: `~{srv-url}/-/cds/saas-provisioning/tenant/{tenantId}`
   - Enable async subscription with timeout
   - Update DB deployer to use Service Manager

### Custom Logic (Optional)

7. **[JAVA] Implement Custom Subscription Handler**
   - Create handler implementing `EventHandler`
   - Use `@ServiceName(TenantProviderService.DEFAULT_NAME)`
   - Handle `EVENT_SUBSCRIBE` for custom initialization (seed data)
   - Handle `EVENT_UNSUBSCRIBE` for custom cleanup

8. **[JAVA] Access Tenant Context**
   - Use `RequestContext.getCurrent(runtime)` to get current tenant
   - Get tenant ID from `ctx.getUserInfo().getTenant()`

### Deployment

9. **[BUILD] Build and Deploy**
   - Run `cds build --for hana` (same as Stage 1)
   - Build MTA with `mbt build`
   - Deploy with `cf deploy`

10. **[CF] Map Tenant Routes**
    - Map routes for each tenant using `cf map-route`
    - Format: `cf map-route <app>-approuter cfapps.<region>.hana.ondemand.com --hostname <tenant>`

### Testing

11. **[TEST] Test Provider Access**
    - Verify provider tenant can access OData services
    - Get OAuth token using provider subaccount credentials

12. **[TEST] Test Subscription Flow**
    - Subscribe from subscriber subaccount via BTP Cockpit
    - Verify HDI container created for subscriber
    - Access application via subscriber-specific URL

13. **[TEST] Test Data Isolation**
    - Create data in provider tenant
    - Verify subscriber tenant has empty database
    - Create data in subscriber tenant
    - Verify isolation between tenants

---

## CAP Built-in Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/-/cds/saas-provisioning/tenant/{tenantId}` | PUT | Subscription callback |
| `/-/cds/saas-provisioning/tenant/{tenantId}` | DELETE | Unsubscription callback |
| `/-/cds/saas-provisioning/dependencies` | GET | Service dependencies |

---

## Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| 403 on subscription callback | Missing mtcallback scope | Add grant-as-authority-to-apps in xs-security.json |
| Subscriber can't access app | Tenant route not mapped | Use `cf map-route` for subscriber hostname |
| HDI container not created | Service Manager not bound | Check Service Manager binding in mta.yaml |
| Token invalid for subscriber | Using provider credentials | Get token from subscriber's XSUAA |

---

## CAP vs Manual Multitenancy

| Aspect | CAP (Automatic) | Manual (Custom) |
|--------|-----------------|-----------------|
| Schema Creation | Automatic via MTX | TenantSchemaService |
| Subscription Callbacks | Built-in endpoints | Custom Controller |
| Tenant Resolution | Automatic from JWT | TenantFilter + TenantContext |
| Database Switching | Automatic | TenantConnectionProvider |
| Migrations | HDI artifacts (.hdbtable) | Liquibase changelogs |
| Configuration | package.json | Multiple Java classes |

---

## Achievements

| Concept | Description |
|---------|-------------|
| CAP MTX | Multitenancy Extension services |
| Automatic Tenant Isolation | HDI container per tenant |
| TenantProviderService | Java handler for subscription events |
| XSUAA broker plan | Multitenant OAuth 2.0 |
| Service Manager container | Dynamic HDI provisioning |
| SaaS Registry | Marketplace & subscription |
| Async Subscription | Long-running subscription with callbacks |

---

## Verification Checklist

- [ ] Provider tenant can access OData services
- [ ] Application visible in BTP Marketplace
- [ ] Subscriber can subscribe successfully
- [ ] Subscriber gets isolated HDI container
- [ ] Subscriber can access via tenant-specific URL
- [ ] Data isolated between tenants
- [ ] Unsubscription cleans up HDI container