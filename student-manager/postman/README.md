# Postman Collection for Student Manager API

This directory contains Postman collection and environments for testing the Student Manager OData V4 API.

## Files

| File | Description |
|------|-------------|
| `Student-Manager-API.postman_collection.json` | API collection with all endpoints |
| `Local.postman_environment.json` | Environment for local development |
| `Cloud.postman_environment.json` | Environment for SAP BTP Cloud Foundry |
| `update-cloud-env.sh` | Script to auto-update Cloud environment credentials |

## Quick Start

### Import into Postman

1. Open Postman
2. Click **Import** button
3. Select all files from this directory
4. The collection and environments will be imported

---

## Local Environment

### Setup

1. Start the local server:
   ```bash
   cd srv
   mvn spring-boot:run
   ```

2. In Postman:
   - Select **"Local"** environment from the dropdown
   - For each request, change **Authorization** tab to **Basic Auth**
   - Use credentials: `admin` / `admin`

### Local Auth Note

The collection uses Bearer token auth by default (for cloud). For local testing:
- Go to **Authorization** tab in each request
- Change type to **Basic Auth**
- Set Username: `admin`, Password: `admin`

Or use the health endpoints which don't require auth.

---

## Cloud Environment (SAP BTP)

### Setup

The Cloud environment is pre-configured with:
- `baseUrl` - Cloud app URL
- `xsuaaUrl` - OAuth token endpoint
- `clientId` - XSUAA client ID
- `clientSecret` - XSUAA client secret

### Usage

1. Select **"Cloud"** environment from the dropdown

2. **Get OAuth Token FIRST:**
   - Go to **Authentication (Cloud)** folder
   - Run **"Get OAuth2 Token (Client Credentials)"** request
   - Token is automatically saved to `accessToken` variable

3. **Make API Requests:**
   - All requests will use the Bearer token automatically
   - Token expires after ~12 hours, re-run token request if needed

### Workflow

```
1. Select Cloud environment
2. Run "Get OAuth2 Token (Client Credentials)" 
3. Token saved to accessToken ✓
4. Run any API request (uses Bearer token automatically)
```

---

## Updating Cloud Credentials

If the app is redeployed, you may need to update credentials:

### Option 1: Use the Script

```bash
cd postman
./update-cloud-env.sh student-manager-srv
```

This script:
- Extracts XSUAA credentials from Cloud Foundry
- Updates `Cloud.postman_environment.json`

### Option 2: Manual Update

1. Get credentials:
   ```bash
   cf env student-manager-srv | grep -A 20 '"xsuaa"'
   ```

2. Update these values in `Cloud.postman_environment.json`:
   - `clientId` → `clientid` from output
   - `clientSecret` → `clientsecret` from output
   - `xsuaaUrl` → `url` from output
   - `baseUrl` → App URL from `cf app student-manager-srv`

---

## Collection Structure

### 1. Authentication (Cloud)
- **Get OAuth2 Token (Client Credentials)** - Get access token ⭐ Run first!
- **Get OAuth2 Token (Password Grant)** - Alternative with user credentials

### 2. Service Metadata
- Get Service Document
- Get Metadata ($metadata)

### 3. Students CRUD
- Get All Students
- Get Student by ID
- Create Student
- Update Student (PATCH)
- Update Student (PUT)
- Delete Student

### 4. OData Queries
- $select - Select Specific Fields
- $filter - Various filter examples
- $orderby - Sorting
- $top & $skip - Pagination
- $count - Counting

### 5. Health Check
- Health Endpoint (no auth)
- Info Endpoint (no auth)

---

## Environment Variables

### Local Environment

| Variable | Value | Description |
|----------|-------|-------------|
| `baseUrl` | `http://localhost:8080` | Local server URL |
| `username` | `admin` | Basic auth username |
| `password` | `admin` | Basic auth password |
| `studentId` | (auto-set) | Current student ID for requests |
| `accessToken` | (unused) | Not used for local |

### Cloud Environment

| Variable | Value | Description |
|----------|-------|-------------|
| `baseUrl` | `https://...cfapps...` | Cloud app URL |
| `xsuaaUrl` | `https://...authentication...` | OAuth token URL |
| `clientId` | `sb-student-manager!...` | XSUAA client ID |
| `clientSecret` | (secret) | XSUAA client secret |
| `accessToken` | (auto-set) | OAuth access token |
| `studentId` | (auto-set) | Current student ID |

---

## Troubleshooting

### "401 Unauthorized" on Cloud

1. Token expired - re-run "Get OAuth2 Token" request
2. Check `accessToken` is set in environment
3. Verify environment is set to "Cloud"

### "Token endpoint returns error"

1. Verify XSUAA credentials are correct
2. Check HANA Cloud is running
3. Re-run `./update-cloud-env.sh` to refresh credentials

### "Connection refused" on Local

1. Ensure local server is running: `mvn spring-boot:run`
2. Check port 8080 is not in use
3. Verify environment is set to "Local"

### Empty Students List on Cloud

This is normal - cloud database starts empty. Create students using the "Create Student" request.

---

## Tips

1. **Auto-save IDs:** Creating or fetching students auto-saves the ID to `studentId` variable
2. **Token auto-save:** OAuth token is auto-saved to `accessToken` after successful auth
3. **Check Console:** Postman console (View → Show Console) shows variable updates
4. **Re-import:** If collection breaks, delete and re-import from these files