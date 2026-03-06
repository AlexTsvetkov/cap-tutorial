# Student Manager

A **SAP Cloud Application Programming Model (CAP)** Java application for managing student records. This project demonstrates CAP Java best practices with OData V4 APIs, Spring Boot, and deployment to SAP BTP Cloud Foundry.

## Features

- ✅ **OData V4 REST API** - Full CRUD operations for Students
- ✅ **CAP Java** - Built with SAP CAP framework for enterprise applications
- ✅ **Spring Boot** - Modern Java backend with auto-configuration
- ✅ **Multi-Database** - H2 (local) and SAP HANA Cloud (production)
- ✅ **Authentication** - Mock auth (local) and XSUAA OAuth2 (cloud)
- ✅ **Health Checks** - Actuator endpoints for BTP monitoring
- ✅ **Validation** - Server-side email validation with proper error responses

## Project Structure

```
student-manager/
├── db/
│   └── schema.cds              # CDS entity definitions
├── srv/
│   ├── service.cds             # Service definition
│   └── src/main/
│       ├── java/               # Java handlers and config
│       └── resources/          # Application configuration
├── postman/                    # API testing collection
├── mta.yaml                    # Multi-target application descriptor
├── xs-security.json            # XSUAA security configuration
└── pom.xml                     # Maven parent POM
```

## Data Model

### Students Entity

| Field | Type | Description |
|-------|------|-------------|
| `ID` | UUID | Primary key (auto-generated) |
| `firstName` | String(100) | First name (required) |
| `lastName` | String(100) | Last name (required) |
| `email` | String(255) | Email address (required, validated) |
| `dateOfBirth` | Date | Date of birth |
| `status` | String(20) | Status (default: 'ACTIVE') |
| `createdAt` | Timestamp | Creation timestamp (managed) |
| `createdBy` | String | Created by user (managed) |
| `modifiedAt` | Timestamp | Last modified timestamp (managed) |
| `modifiedBy` | String | Modified by user (managed) |

## Prerequisites

- **Java 21** (required for cloud deployment)
- **Maven 3.8+**
- **Node.js 18+** (for CDS build tools)
- **@sap/cds-dk** - CDS development kit
- **MBT** - MTA Build Tool (for cloud deployment)
- **CF CLI** with **multiapps plugin** (for cloud deployment)

### Installing Prerequisites

```bash
# Install CDS Development Kit
npm install -g @sap/cds-dk

# Install MTA Build Tool
npm install -g mbt

# Install CF CLI (macOS)
brew install cloudfoundry/tap/cf-cli@8

# Install multiapps plugin for MTA deployment
cf install-plugin multiapps

# Verify installations
cds version
mbt --version
cf version
cf plugins | grep multiapps
```

## Quick Start

### Local Development

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd student-manager
   ```

2. **Build and run:**
   ```bash
   cd srv
   mvn spring-boot:run
   ```

3. **Access the application:**
   - OData Service: http://localhost:8080/odata/v4/StudentService
   - H2 Console: http://localhost:8080/h2-console
   - Health Check: http://localhost:8080/actuator/health

4. **Authentication (Local):**
   - Username: `admin` or `user`
   - Password: `admin` or `user`

### API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/odata/v4/StudentService/Students` | List all students |
| GET | `/odata/v4/StudentService/Students({id})` | Get student by ID |
| POST | `/odata/v4/StudentService/Students` | Create new student |
| PATCH | `/odata/v4/StudentService/Students({id})` | Update student |
| DELETE | `/odata/v4/StudentService/Students({id})` | Delete student |
| GET | `/odata/v4/StudentService/$metadata` | OData metadata |

### Example Requests

**Create a Student:**
```bash
curl -X POST http://localhost:8080/odata/v4/StudentService/Students \
  -H "Content-Type: application/json" \
  -u admin:admin \
  -d '{
    "firstName": "John",
    "lastName": "Doe",
    "email": "john.doe@example.com",
    "dateOfBirth": "2000-01-15",
    "status": "ACTIVE"
  }'
```

**Get All Students:**
```bash
curl http://localhost:8080/odata/v4/StudentService/Students \
  -u admin:admin
```

**OData Query Examples:**
```bash
# Filter by status
curl "http://localhost:8080/odata/v4/StudentService/Students?\$filter=status eq 'ACTIVE'" -u admin:admin

# Select specific fields
curl "http://localhost:8080/odata/v4/StudentService/Students?\$select=firstName,lastName,email" -u admin:admin

# Sort by last name
curl "http://localhost:8080/odata/v4/StudentService/Students?\$orderby=lastName asc" -u admin:admin

# Pagination
curl "http://localhost:8080/odata/v4/StudentService/Students?\$top=10&\$skip=0" -u admin:admin
```

## Cloud Deployment (SAP BTP)

### Prerequisites

1. SAP BTP Cloud Foundry account (Trial or Production)
2. CF CLI installed and logged in
3. **SAP HANA Cloud instance** (must be created first!)

### Step 1: Create SAP HANA Cloud Instance (Required!)

⚠️ **IMPORTANT**: You must create a HANA Cloud instance BEFORE deploying the app. The HDI container service requires an existing HANA Cloud database.

**For Trial Accounts:**

1. Go to [SAP BTP Cockpit](https://cockpit.hanatrial.ondemand.com/)
2. Navigate to your **Subaccount** → **Service Marketplace**
3. Search for **"SAP HANA Cloud"**
4. Click **Create**
5. **Choose Plan:**
   | Plan | Description | Recommended |
   |------|-------------|-------------|
   | `hana-free` | Free tier, limited resources | ✅ **For Trial** |
   
   **Select: `hana-free`**

6. Configure the instance:
   - **Instance Name:** `student-manager-hana` (or any name)
   - **Administrator Password:** (set a secure password, remember it!)
   - **Allowed Connections:** "Allow all IP addresses" (for trial)
   - **Memory:** 32 GB (default for free tier)

7. Click **Create**
8. **Wait 10-20 minutes** for the instance to be created and reach "Running" state

**Alternative - Via CF CLI (Recommended):**

Use the provided config file to create HANA Cloud via command line:

```bash
# Create HANA Cloud instance
cf create-service hana-cloud hana-free student-manager-hana -c hana-cloud-config.json
```

⚠️ **Important:** Edit `hana-cloud-config.json` and change the `systempassword` to your own secure password!

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

Password requirements:
- At least 8 characters
- Mix of uppercase, lowercase, numbers, special characters recommended

**Via SAP HANA Cloud Central:**

1. In BTP Cockpit, go to **SAP HANA Cloud** in left menu
2. Click **"Create Instance"** button
3. Select **SAP HANA Database**
4. Choose **Free Tier** configuration
5. Follow the wizard to create

**Verify HANA Cloud is running:**
```bash
cf services
# Should show your HANA Cloud instance
```

### Step 2: Deploy the Application

1. **Login to Cloud Foundry:**
   ```bash
   cf login -a https://api.cf.us10-001.hana.ondemand.com
   ```

2. **Build the MTA archive:**
   
   ⚠️ **IMPORTANT**: You must generate HANA artifacts before building the MTA archive!
   
   ```bash
   # Option A: Use npm script (recommended)
   npm run build:mta
   
   # Option B: Manual commands
   cds build --for hana    # Generate HANA table/view definitions
   mbt build               # Build MTA archive (includes mvn package)
   ```

3. **Deploy to Cloud Foundry:**
   ```bash
   cf deploy mta_archives/student-manager_1.0.0.mtar
   ```

4. **Check deployment status:**
   ```bash
   cf apps
   cf services
   ```

### Step 3: Get Application URL

```bash
cf app student-manager-srv
```

### Cloud Authentication

The cloud deployment uses XSUAA for OAuth2 authentication. Get credentials:

```bash
cf env student-manager-srv
```

Or use the auto-configure script:
```bash
cd postman
./update-cloud-env.sh student-manager-srv
```

Find the XSUAA credentials in the `VCAP_SERVICES` section.

### Troubleshooting Deployment

#### Error: "Could not create service student-manager-db"

**Cause**: SAP HANA Cloud instance doesn't exist or is not running.

**Solution**:
1. Go to BTP Cockpit → SAP HANA Cloud
2. Create a HANA Cloud instance (see Step 1 above)
3. Wait for it to be in "Running" state
4. Re-run deployment: `cf deploy mta_archives/*.mtar`

#### Error: "HANA Database instance is stopped"

**Cause**: HANA Cloud instance exists but is stopped (trial instances auto-stop after inactivity).

**Solution - Start HANA Cloud Instance:**

**Step 1: Subscribe to SAP HANA Cloud Tools**
1. Go to BTP Cockpit → Your Subaccount → **Service Marketplace**
2. Search for **"SAP HANA Cloud"**
3. Click **Create** → Select plan: **"tools"**
4. Wait for subscription to complete

**Step 2: Assign Administrator Role**
1. Go to **Security** → **Role Collections**
2. Find **"SAP HANA Cloud Administrator"**
3. Click to open, then **Edit**
4. Add your user (email address) under **Users**
5. **Save**

**Step 3: Start HANA Instance**
1. Go to **Instances and Subscriptions** → **Subscriptions** tab
2. Find **"SAP HANA Cloud"** subscription
3. Click **"Go to Application"** (opens HANA Cloud Dashboard)
4. In the dashboard, find your HANA instance
5. Click the **three dots (⋮)** menu → **Start**
6. Wait 2-5 minutes for status to show "Running"

**Step 4: Retry Deployment**
```bash
cf deploy -i <deployment-id> -a retry
```
Or redeploy:
```bash
cf deploy mta_archives/*.mtar
```

⚠️ **Note**: Trial HANA Cloud instances automatically stop after periods of inactivity. You'll need to restart them before each development session.

#### Error: "Insufficient resources"

**Cause**: Trial account resource limits reached.

**Solution**:
1. Delete unused apps: `cf apps` then `cf delete <app-name>`
2. Delete unused services: `cf services` then `cf delete-service <service-name>`
3. Reduce memory in mta.yaml if needed

#### Error: "UnsupportedClassVersionError" (Java version mismatch)

**Cause**: Application compiled with Java 21 but runtime using Java 17.

**Error message:**
```
UnsupportedClassVersionError: com/tutorial/studentmanager/Application has been compiled by 
a more recent version of the Java Runtime (class file version 65.0), this version of the 
Java Runtime only recognizes class file versions up to 61.0
```

**Solution**: Ensure `mta.yaml` specifies Java 21:
```yaml
properties:
  JBP_CONFIG_SAP_MACHINE_JRE: '{ version: 21.+ }'
```

#### Error: "requires a peer of '@sap/hana-client' or 'hdb'"

**Cause**: HDI deployer missing database client dependency.

**Solution**: Add `hdb` to `db/package.json`:
```json
{
  "dependencies": {
    "@sap/hdi-deploy": "^5",
    "hdb": "^0.19.0"
  }
}
```

Then rebuild and redeploy:
```bash
cd db && npm install && cd ..
mbt build
cf deploy mta_archives/*.mtar
```

#### Error: "Table TUTORIAL_STUDENTS not found" (500 Error)

**Cause**: HANA database tables were not deployed. The `db/src/gen/` folder with compiled CDS artifacts is missing.

**Error message:**
```
CdsDataException: Target 'StudentService.Students' does not exist as table or view
```

**Solution**: Run `cds build --for hana` before building the MTA archive:
```bash
# Generate HANA artifacts (creates db/src/gen/*.hdbtable, *.hdbview)
cds build --for hana

# Rebuild and redeploy
npm run build:mta
cf deploy mta_archives/student-manager_1.0.0.mtar
```

**Why this happens**: The `mvn clean package` command only generates Java artifacts (`cds build --for java`), not HANA artifacts. See the "Understanding CDS Build Tasks" section for details.

#### Linking HDI Container to Existing HANA Cloud

If you have an existing HANA Cloud instance (e.g., from another project), you can link the HDI container to it:

```bash
# Get the HANA Cloud instance GUID
cf service <your-hana-instance> --guid

# Create HDI container linked to existing HANA
cf create-service hana hdi-shared student-manager-db -c '{"database_id":"<guid>"}'
```

## Postman Collection

A complete Postman collection is available in the `postman/` directory:

- `Student-Manager-API.postman_collection.json` - API collection
- `Local.postman_environment.json` - Local environment
- `Cloud.postman_environment.json` - Cloud environment

See [postman/README.md](postman/README.md) for detailed usage instructions.

## Validation

The API validates input data:

| Validation | Field | Error |
|------------|-------|-------|
| Email format | `email` | Must contain `@` character |

**Invalid Request Example:**
```json
POST /odata/v4/StudentService/Students
{ "firstName": "Test", "lastName": "User", "email": "invalid-email" }
```

**Error Response (400 Bad Request):**
```json
{
  "error": {
    "code": "400",
    "message": "Invalid email format: invalid-email. Email must contain '@' character."
  }
}
```

## Sample Data

The application is seeded with sample students (local H2 only):

| Name | Email | Status |
|------|-------|--------|
| Alice Johnson | alice@example.com | ACTIVE |
| Bob Smith | bob@example.com | ACTIVE |
| Carol Williams | carol@example.com | INACTIVE |

## Configuration

### Profiles

| Profile | Database | Authentication | Usage |
|---------|----------|----------------|-------|
| `default` | H2 (in-memory) | Mock users | Local development |
| `cloud` | SAP HANA Cloud | XSUAA OAuth2 | Production |

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PORT` | Server port | 8080 |
| `VCAP_SERVICES` | Cloud Foundry services | - |

## Health Checks

Health endpoints are accessible without authentication (required for BTP):

| Endpoint | Auth | Description |
|----------|------|-------------|
| `/actuator/health` | ❌ | Basic health status |
| `/actuator/health/liveness` | ❌ | Kubernetes liveness |
| `/actuator/health/readiness` | ❌ | Kubernetes readiness |
| `/actuator/info` | ❌ | Application info |

## Technology Stack

- **Backend:** Java 21, Spring Boot 3.x
- **Framework:** SAP CAP Java 4.x
- **Database:** H2 (local), SAP HANA Cloud (production)
- **Security:** Spring Security, SAP XSUAA
- **Build:** Maven, MTA Build Tool
- **API:** OData V4

## Development

### Build

#### Understanding CDS Build Tasks

CAP separates build tasks for different deployment targets:

| Command | Target | Output | Purpose |
|---------|--------|--------|---------|
| `cds build --for java` | Java service | `srv/src/main/resources/edmx/` | OData metadata, CSN for Java runtime |
| `cds build --for hana` | HANA database | `db/src/gen/` | `.hdbtable`, `.hdbview` for HDI deployer |

**Why `mvn clean package` doesn't generate HANA artifacts:**

The CDS Maven plugin (`cds-maven-plugin`) only runs `cds build --for java` because:
- Maven builds the **Java service module** (`srv/`)
- HANA artifacts belong to the **database module** (`db/`), which is a Node.js-based HDI deployer
- These are separate concerns with separate build pipelines

```
mvn clean package
    └── cds-maven-plugin
        └── cds build --for java     ✅ Runs automatically
                                      ❌ Does NOT run --for hana
```

#### Build Commands

```bash
# Full build for local development (Java only)
mvn clean install

# Build for cloud deployment (includes HANA artifacts)
npm run build:all
# Or manually:
cds build --for hana && mvn clean package -DskipTests

# Build MTA archive for deployment
npm run build:mta
# Or manually:
cds build --for hana && mbt build

# Build srv module only
cd srv && mvn clean compile

# Generate CDS artifacts (Java only)
cd srv && mvn cds:generate

# Generate HANA artifacts only
cds build --for hana
```

#### Cloud Deployment Build Workflow

⚠️ **IMPORTANT**: Always run `cds build --for hana` before building the MTA archive!

```bash
# Complete build and deploy workflow
npm run build:mta     # Builds HANA artifacts + MTA archive
cf deploy mta_archives/student-manager_1.0.0.mtar
```

Or step by step:
```bash
# 1. Generate HANA database artifacts
cds build --for hana

# 2. Build MTA archive (includes mvn package)
mbt build

# 3. Deploy to Cloud Foundry
cf deploy mta_archives/student-manager_1.0.0.mtar
```

### Testing

```bash
# Run tests
mvn test

# Run with specific profile
mvn spring-boot:run -Dspring-boot.run.profiles=default
```

## License

This project is for educational purposes as part of SAP CAP tutorials.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request