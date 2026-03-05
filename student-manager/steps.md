__Step 5 - Data Model:__

- `student-manager/db/schema.cds` - Students entity with cuid, managed aspects

__Step 6 - Service & Handler:__

- `student-manager/srv/service.cds` - StudentService exposing Students entity
- `student-manager/srv/src/main/java/com/tutorial/studentmanager/handlers/StudentServiceHandler.java` - Email validation handler

__Step 7 - Initial Data:__

- `student-manager/srv/src/main/resources/data.sql` - 3 test student records

__Step 8 - Configuration:__

- `student-manager/srv/src/main/resources/application.yaml` - Full config with default (H2) and cloud (HANA/XSUAA) profiles

__Step 11 - BTP Services:__

- `student-manager/srv/pom.xml` - Added cds-feature-hana, cds-starter-cloudfoundry, spring-boot-starter-actuator
- `student-manager/package.json` - Updated with CDS production config

__Step 12 - Deployment Descriptors:__

- `student-manager/xs-security.json` - XSUAA configuration with roles and role collections
- `student-manager/mta.yaml` - MTA deployment descriptor with srv, db-deployer, approuter modules and HANA/XSUAA/Logging/Autoscaler resources
- `student-manager/approuter/package.json` - Approuter dependencies
- `student-manager/approuter/xs-app.json` - Routing configuration
- `student-manager/db/package.json` - HDI deployer dependencies
