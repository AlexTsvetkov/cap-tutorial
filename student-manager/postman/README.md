# Student Manager API - Postman Collection

This folder contains a Postman collection and environments for testing the Student Manager CAP Java OData V4 API.

## Files

| File | Description |
|------|-------------|
| `Student-Manager-API.postman_collection.json` | Main API collection with all requests |
| `Local.postman_environment.json` | Environment for local development |
| `Cloud.postman_environment.json` | Environment for SAP BTP Cloud Foundry |

## Import into Postman

1. Open Postman
2. Click **Import** button
3. Drag all JSON files or select them
4. Both collection and environments will be imported

## Environments

### Local Environment

Pre-configured for local development with H2 in-memory database.

| Variable | Value | Description |
|----------|-------|-------------|
| `baseUrl` | `http://localhost:8080` | Local server URL |
| `username` | `admin` | Mock user (admin or user) |
| `password` | `admin` | Mock password |
| `studentId` | `11111111-...` | Sample student ID for testing |

**Authentication:** Basic Auth (automatic)

### Cloud Environment (BTP)

For SAP BTP Cloud Foundry deployment with XSUAA authentication.

| Variable | Value | Description |
|----------|-------|-------------|
| `baseUrl` | `https://your-app...` | Cloud Foundry app URL |
| `xsuaaUrl` | `https://...authentication...` | XSUAA OAuth2 endpoint |
| `clientId` | `sb-student-manager!tXXXX` | XSUAA client ID |
| `clientSecret` | (secret) | XSUAA client secret |
| `accessToken` | (auto-filled) | OAuth2 access token |

**Setup Cloud Environment:**

1. Deploy the app to Cloud Foundry:
   ```bash
   cf push
   ```

2. Get XSUAA credentials:
   ```bash
   cf env student-manager-srv
   ```

3. Find the XSUAA section in the output and copy:
   - `url` → `xsuaaUrl`
   - `clientid` → `clientId`
   - `clientsecret` → `clientSecret`

4. Get the app URL:
   ```bash
   cf app student-manager-srv
   ```
   Copy the route URL → `baseUrl`

5. Run "Get OAuth2 Token" request to authenticate

## Collection Structure

```
Student Manager API
├── Service Metadata
│   ├── Get Service Document
│   └── Get Metadata ($metadata)
├── Students CRUD
│   ├── Get All Students
│   ├── Get Student by ID
│   ├── Create Student
│   ├── Update Student (PATCH)
│   ├── Update Student (PUT)
│   └── Delete Student
├── OData Queries
│   ├── $select - Select Specific Fields
│   ├── $filter - Active Students
│   ├── $filter - By Last Name (contains)
│   ├── $filter - Born After Date
│   ├── $orderby - Sort by Last Name
│   ├── $orderby - Sort by Created Date (desc)
│   ├── $top & $skip - Pagination
│   ├── $count - Get Total Count
│   ├── $count=true - Include Count in Response
│   └── Combined Query
├── Authentication (Cloud)
│   ├── Get OAuth2 Token (Client Credentials)
│   └── Get OAuth2 Token (Password Grant)
└── Health Check
    ├── Health Endpoint
    └── Info Endpoint
```

## Quick Start

### Local Testing

1. Start the application locally:
   ```bash
   cd srv && mvn spring-boot:run
   ```

2. Select **"Student Manager - Local"** environment in Postman

3. Run any request - Basic Auth is pre-configured

### Cloud Testing

1. Select **"Student Manager - Cloud (BTP)"** environment

2. Configure environment variables (see setup above)

3. Run **"Get OAuth2 Token (Client Credentials)"** request

4. Token is auto-saved - now run other requests

## Sample Data

The application is seeded with sample students:

| ID | Name | Email | Status |
|----|------|-------|--------|
| `11111111-1111-1111-1111-111111111111` | Alice Johnson | alice@example.com | ACTIVE |
| `22222222-2222-2222-2222-222222222222` | Bob Smith | bob@example.com | ACTIVE |
| `33333333-3333-3333-3333-333333333333` | Carol Williams | carol@example.com | INACTIVE |

## OData Query Examples

```
# Filter active students
GET /odata/v4/StudentService/Students?$filter=status eq 'ACTIVE'

# Select specific fields
GET /odata/v4/StudentService/Students?$select=firstName,lastName,email

# Sort by last name
GET /odata/v4/StudentService/Students?$orderby=lastName asc

# Pagination (page 2, 10 per page)
GET /odata/v4/StudentService/Students?$top=10&$skip=10

# Combined query
GET /odata/v4/StudentService/Students?$filter=status eq 'ACTIVE'&$select=firstName,lastName&$orderby=lastName&$top=5
```

## Validation

The API validates input data and returns appropriate error responses.

### Email Validation

When creating a student, the email field must contain an `@` character. Invalid emails return HTTP 400:

**Request:**
```json
POST /odata/v4/StudentService/Students
{
  "firstName": "Test",
  "lastName": "User",
  "email": "invalid-email"
}
```

**Response (400 Bad Request):**
```json
{
  "error": {
    "code": "400",
    "message": "Invalid email format: invalid-email. Email must contain '@' character."
  }
}
```

## Troubleshooting

### 400 Bad Request

- Check the request body for validation errors
- Email must contain `@` character
- Review the error message for specific field issues

### 401 Unauthorized (Local)

- Check username/password in environment (admin/admin or user/user)
- Ensure Basic Auth is enabled on the request

### 401 Unauthorized (Cloud)

- Run "Get OAuth2 Token" request first
- Check that `accessToken` variable is set
- Verify XSUAA credentials are correct

### 403 Forbidden

- User doesn't have required role
- Check `xs-security.json` for role requirements

### Connection Refused (Local)

- Ensure app is running: `mvn spring-boot:run`
- Check port 8080 is not in use

## Health Checks

The health endpoints are accessible without authentication (required for BTP health monitoring):

```bash
# Basic health check (no auth required)
curl http://localhost:8080/actuator/health

# Returns: {"status":"UP"}
```

| Endpoint | Auth Required | Description |
|----------|---------------|-------------|
| `/actuator/health` | ❌ No | Basic health status |
| `/actuator/health/liveness` | ❌ No | Kubernetes liveness probe |
| `/actuator/health/readiness` | ❌ No | Kubernetes readiness probe |
| `/actuator/info` | ❌ No | Application info |
