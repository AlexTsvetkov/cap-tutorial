# CAP Java Tutorial - Student Manager

A complete SAP CAP Java application demonstrating how to build, test, and deploy an OData V4 service to SAP BTP Cloud Foundry.

## 🎯 What You'll Learn

- Define data models using CDS (Core Data Services)
- Create OData V4 services with automatic CRUD operations
- Add custom business logic with Java event handlers
- Configure local development with H2 database and mock authentication
- Deploy to SAP BTP with HANA, XSUAA, and other cloud services

## 📁 Project Structure

```
cap-tutorial/
├── README.md                    # This file
├── presentation_script.md       # Full workshop presentation script
└── student-manager/             # CAP Java application
    ├── pom.xml                  # Parent Maven POM
    ├── package.json             # CDS dependencies
    ├── mta.yaml                 # Deployment descriptor
    ├── xs-security.json         # XSUAA security config
    ├── db/
    │   ├── schema.cds           # Data model
    │   └── package.json         # HDI deployer config
    ├── srv/
    │   ├── pom.xml              # Service module POM
    │   ├── service.cds          # Service definition
    │   └── src/main/
    │       ├── java/            # Java source code
    │       └── resources/       # Configuration files
    └── approuter/               # Application Router
        ├── package.json
        └── xs-app.json
```

## 🚀 Quick Start

### Prerequisites

- Node.js ≥18
- Java JDK 17+
- Maven 3.8+
- @sap/cds-dk (`npm install -g @sap/cds-dk`)

### Run Locally

```bash
# Clone the repository
git clone git@github.com:AlexTsvetkov/cap-tutorial.git
cd cap-tutorial/student-manager

# Install dependencies
npm install

# Build and run
mvn clean spring-boot:run -pl srv
```

### Test the API

The application runs at `http://localhost:8080`

**Authentication:** Basic Auth with `admin/admin` or `user/user`

| Endpoint | Description |
|----------|-------------|
| `/odata/v4/StudentService/$metadata` | OData metadata |
| `/odata/v4/StudentService/Students` | List all students |
| `/odata/v4/StudentService/Students?$filter=status eq 'ACTIVE'` | Filter students |

### Example: Create a Student

```bash
curl -X POST http://localhost:8080/odata/v4/StudentService/Students \
  -u admin:admin \
  -H "Content-Type: application/json" \
  -d '{
    "firstName": "John",
    "lastName": "Doe",
    "email": "john.doe@example.com",
    "status": "ACTIVE"
  }'
```

## 🏗️ Architecture

```
┌─────────────────────────────────────────┐
│           Local Development             │
│  ┌─────────────┐    ┌────────────────┐  │
│  │  Spring Boot │    │   H2 Database  │  │
│  │  + CAP Java  │───▶│  (in-memory)   │  │
│  └─────────────┘    └────────────────┘  │
│        │                                 │
│        ▼                                 │
│  Mock Authentication (Basic Auth)       │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│           SAP BTP Cloud Foundry         │
│  ┌─────────────┐    ┌────────────────┐  │
│  │  Approuter  │───▶│  Java Backend  │  │
│  └──────┬──────┘    └───────┬────────┘  │
│         │                   │           │
│         ▼                   ▼           │
│  ┌─────────────┐    ┌────────────────┐  │
│  │   XSUAA     │    │  HANA Cloud    │  │
│  │  (OAuth2)   │    │ (HDI Container)│  │
│  └─────────────┘    └────────────────┘  │
└─────────────────────────────────────────┘
```

## 📚 Documentation

- **[steps.md](student-manager/steps.md)** - Step-by-step implementation guide
- **[presentation_script.md](student-manager/presentation_script.md)** - Full workshop script with explanations

## 🔧 Key Technologies

| Technology | Purpose |
|------------|---------|
| **SAP CAP** | Application programming model |
| **CDS** | Data modeling language |
| **Spring Boot** | Java runtime framework |
| **OData V4** | REST API protocol |
| **HANA** | Production database |
| **XSUAA** | OAuth2 authentication |

## 📦 Deploy to SAP BTP

```bash
# Login to Cloud Foundry
cf login -a https://api.cf.us10-001.hana.ondemand.com

# Build MTA archive
mbt build

# Deploy
cf deploy mta_archives/student-manager_1.0.0.mtar
```

## 🔗 Resources

- [CAP Java Documentation](https://cap.cloud.sap/docs/java/)
- [CDS Language Reference](https://cap.cloud.sap/docs/cds/)
- [SAP BTP Trial Account](https://account.hanatrial.ondemand.com/)
- [CAP Samples on GitHub](https://github.com/SAP-samples/cloud-cap-samples-java)

## 📄 License

This project is licensed under the MIT License.