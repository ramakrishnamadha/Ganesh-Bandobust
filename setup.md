# Ganesh Bandobust 2026 — Contributor Setup & Development Guide

Welcome to the **Ganesh Bandobust 2026 Police Application Project**. This repository powers the mission-critical operational platform deployed for the annual Ganesh festival bandobust.

---

## 1. System Architecture Overview

The system is architected into two complementary components:

```mermaid
graph TD
    subgraph MobileApp ["Mobile Application (Flutter)"]
        A[Field Work Tool] --> B[Officer Daily Visits & Targets]
        A --> C[GPID QR Scanning & Validation]
        A --> D[AR Mandap Measurement]
        A --> E[GPS Capture & Geofence Checks]
        A --> F[Evidence Capture & Photo/Video Upload]
    end

    subgraph WebApp ["Web Application (Next.js 16 + Prisma 7)"]
        G[Command & Monitoring Cockpit] --> H[Executive Analytics Dashboards]
        G --> I[6-Tier Hierarchy Drill-down]
        G --> J[Officer Target vs Achievement Ranking]
        G --> K[Category-Wise Deficiency Analysis]
        G --> L[Live Spatial Officer Tracking]
    end

    subgraph Database ["PostgreSQL & Master API"]
        M[(PostgreSQL Database)]
        N[Upstream Ganesh Portal Master API]
    end

    MobileApp <--> WebApp
    WebApp <--> M
    WebApp <--> N
```

- **Mobile Application (`mobile/`)**: **Field Work Tool** for on-duty police officers (PC/HC to SHO/ACP/DCP). Handles QR/GPID scanning, AR measurement, Stage 1–3 inspection checklists, GPS-geofenced physical visit recording, and offline caching.
- **Web Application (`web/`)**: **Command & Monitoring Cockpit** for supervisory officers, Commissionerate headquarters, and field commanders. Provides real-time analytics, 6-tier hierarchy drill-down, officer achievement leaderboards, and deficiency tracking.

---

## 2. Prerequisites

Ensure your development environment meets the following minimum requirements:

| Tool | Minimum Version | Recommended Version | Notes |
| :--- | :--- | :--- | :--- |
| **Node.js** | `v20.0.0+` | `v20.x LTS` or `v22.x LTS` | Required for `web/` |
| **npm** | `v10.0.0+` | Bundled with Node | Package manager |
| **PostgreSQL** | `15.0+` | `16.x` | Database engine |
| **Flutter SDK** | `3.13.1+` | `3.19.x+` (Dart 3.3+) | Required for `mobile/` |
| **Android SDK** | API Level 33+ | API Level 34 | For mobile APK build & device testing |
| **Git** | `2.34+` | Latest | Version control |

---

## 3. Web Application Setup (`web/`)

### Step 3.1: Navigate to Web Directory
```bash
cd web
```

### Step 3.2: Install Dependencies
```bash
npm install
```

> [!IMPORTANT]
> **Do NOT run `npm audit fix --force`**:
> npm may show 4 high-severity vulnerabilities relating to transitive packages (`deepmerge-ts`, `mysql2`) bundled inside Prisma CLI tooling. Running `npm audit fix --force` will **downgrade Prisma from v7 to v6.19.3**, which is a **breaking change** that breaks Prisma 7 adapters (`@prisma/adapter-pg`) and client generation.
>
> - `mysql2` is unused in this project (we use PostgreSQL via `pg`).
> - `deepmerge-ts` is an internal CLI configuration dependency.
> - If npm prompts `warn allow-scripts`, approve Prisma scripts:
>   ```bash
>   npm approve-scripts prisma @prisma/engines unrs-resolver
>   ```

### Step 3.3: Environment Configuration
Create or verify `.env` in the `web/` directory:

```env
# PostgreSQL Database Connection
DATABASE_URL="postgresql://ganesh_app:Ganesh@2026@localhost:5432/ganesh_bandobust?schema=public"

# Upstream Police Master API Credentials
GANESH_PRE_GEO_API_URL="https://tscopsm.tspolice.gov.in:8085/logicshore.svc/Ganesh2025list"
GANESH_PRE_GEO_AUTH="VGdjb3BAdHNwb2xpY2U6VGdjb3AyazI0IyN0Z2NvcEA="
GANESH_PRE_GEO_API_KEY="2c55461eaa3494e215c260c49dedd684"

# Session Security
GANESH_WEB_SESSION_SECRET="GaneshBandobust2026SecureSessionSecretKey01"
```

### Step 3.4: Generate Prisma Client & Sync Database
```bash
# Generate the Prisma 7 typed client
npx prisma generate

# Sync schema with local database (development only)
npx prisma db push
```

### Step 3.5: Run the Web Development Server
```bash
npm run dev
```
Open [http://localhost:3000](http://localhost:3000) in your browser.

---

## 4. Mobile Application Setup (`mobile/`)

### Step 4.1: Navigate to Mobile Directory
```bash
cd mobile
```

### Step 4.2: Install Flutter Packages
```bash
flutter pub get
```

> **Note on Local Plugins**: The mobile project includes a bundled local AR plugin located at `plugins/ar_flutter_plugin_2`. `flutter pub get` will automatically resolve this path dependency.

### Step 4.3: Run the Mobile App
Ensure an Android device or emulator with ARCore support is connected:
```bash
flutter run
```

### Step 4.4: Build Debug/Release APK
```bash
# Build debug APK for testing
flutter build apk --debug

# Build release APK for deployment
flutter build apk --release
```

---

## 5. Phase 1 APIs & Core Features Reference

The backend provides the following operational and analytics endpoints:

### 1. `/api/targets/my-targets` (Mobile Officer Dashboard)
- **Method**: `GET`, `POST`
- **Purpose**:
  - `GET`: Returns the officer's daily target quota, completed visits, pending mandaps, and compliance status.
  - `POST`: Logs a physical visit with GPS coordinates, verifies mandap geofencing, updates quotas, and caches progress in `DailyOfficerTargetSummary`.
- **Key Params**: `?date=YYYY-MM-DD&filter=all|pending|completed`

### 2. `/api/targets/reports` (6-Tier Hierarchy Drill-Down)
- **Method**: `GET`
- **Purpose**: Enables supervisory command hierarchy monitoring from Commissionerate down to individual officers.
- **Key Params**:
  - `level`: `commissionerate` | `range` | `zone` | `division` | `ps` | `officer`
  - `rangeName`, `zoneName`, `divisionName`, `policeStationName`
  - `date`: `YYYY-MM-DD` (defaults to current date in IST)

### 3. `/api/analytics/overview` (Executive Progress Overview)
- **Method**: `GET`
- **Purpose**: Unified cockpit overview delivering:
  - Total registered GPIDs in jurisdiction & sensitive mandap counts.
  - Stage 1 (Pre-Installation) completion count & %.
  - Stage 2 (Installation) completion count, % and pooja-pending flags.
  - Stage 3 (Festivity) today's physical visits vs quota, pending mandaps today, and cumulative progress.
  - Jurisdiction-level comparison table.

### 4. `/api/analytics/officer-performance` (Target vs Achievement Ranking)
- **Method**: `GET`
- **Purpose**: Real-time officer performance ranking and leaderboard:
  - Top 5 achievers & Bottom 5 deficit officers.
  - Achievement distribution (Completed, On Track, Deficit, Not Started).
  - Search, pagination (`page`, `pageSize`), and multi-field sorting (`sortBy=compliance|completed|deficit|name`).

### 5. `/api/analytics/deficiencies` (Category-Wise Violation Analysis)
- **Method**: `GET`
- **Purpose**: Safety and regulatory violation monitoring across 10 standardized categories:
  - `SOUND_VIOLATION`, `FIRE_SAFETY`, `ELECTRICAL_HAZARD`, `VOLUNTEER_ABSENCE`, `TRAFFIC_OBSTRUCTION`, `CCTV_SECURITY`, `UNAUTHORIZED_STRUCTURE`, `POOJA_TIMING`, `SANITATION_HYGIENE`, `OTHER`.
  - Tracks remediation follow-up (`followUp=pending|resolved`).
  - Spatial distribution by Police Station and paginated evidence audit feed.

---

## 6. Testing & Validation Procedures

### 6.1: Static Type Checking
Always run TypeScript validation inside `web/` before making any commits:
```bash
cd web
npx tsc --noEmit
```
*Expected Result: Zero errors (exit code 0).*

### 6.2: Build Validation
Ensure Next.js compiles cleanly for production:
```bash
cd web
npm run build
```

---

## 7. Testing Endpoints via cURL / PowerShell

All endpoints require session authentication. Supply either the cookie header or `Authorization: Bearer <session_token>`.

### Test 1: Officer Daily Targets (`/api/targets/my-targets`)
```bash
curl -X GET "http://localhost:3000/api/targets/my-targets?filter=all" \
  -H "Authorization: Bearer YOUR_SESSION_TOKEN" \
  -H "Accept: application/json"
```

### Test 2: 6-Tier Hierarchy Report (`/api/targets/reports`)
```bash
# Zone-level breakdown
curl -X GET "http://localhost:3000/api/targets/reports?level=zone" \
  -H "Authorization: Bearer YOUR_SESSION_TOKEN" \
  -H "Accept: application/json"

# Police Station level breakdown
curl -X GET "http://localhost:3000/api/targets/reports?level=ps" \
  -H "Authorization: Bearer YOUR_SESSION_TOKEN" \
  -H "Accept: application/json"
```

### Test 3: Executive Analytics Overview (`/api/analytics/overview`)
```bash
curl -X GET "http://localhost:3000/api/analytics/overview" \
  -H "Authorization: Bearer YOUR_SESSION_TOKEN" \
  -H "Accept: application/json"
```

### Test 4: Officer Performance Ranking (`/api/analytics/officer-performance`)
```bash
curl -X GET "http://localhost:3000/api/analytics/officer-performance?sortBy=compliance&sortOrder=desc&page=1&pageSize=20" \
  -H "Authorization: Bearer YOUR_SESSION_TOKEN" \
  -H "Accept: application/json"
```

### Test 5: Category-Wise Deficiencies (`/api/analytics/deficiencies`)
```bash
# All unresolved deficiencies
curl -X GET "http://localhost:3000/api/analytics/deficiencies?followUp=pending" \
  -H "Authorization: Bearer YOUR_SESSION_TOKEN" \
  -H "Accept: application/json"

# Specific category filter
curl -X GET "http://localhost:3000/api/analytics/deficiencies?category=SOUND_VIOLATION" \
  -H "Authorization: Bearer YOUR_SESSION_TOKEN" \
  -H "Accept: application/json"
```

---

## 8. Contributor Guidelines & Architecture Rules

1. **Protect Completed Modules**:
   Do NOT modify or refactor the following verified modules unless explicitly instructed:
   - Stage 1 Pre-Installation Verification
   - Stage 2 Installation Verification
   - Stage 3 Festivity Check Logic
   - GPID Validation & Master Synchronization
   - QR Scanning Integration
   - Existing Prisma Schema Models
2. **Strict Jurisdictional Scoping**:
   Always enforce officer hierarchy permissions (`allZones`, `zoneName`, `divisionName`, `policeStationAccesses`). Never bypass authorization checks.
3. **Keep Code Clean**:
   - Write strict TypeScript with explicit types.
   - Do not commit temporary test scripts or scratch files.
   - Do not hard-code credentials or fallback authentication keys.
4. **Git Discipline**:
   - Always run `npx tsc --noEmit` before staging changes.
   - Never push directly to remote or deploy without explicit supervisory approval.