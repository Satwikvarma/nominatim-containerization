# Architecture

This document explains the high-level architecture and request lifecycle for **nominatim-containerization**.

## 1) System Architecture

```mermaid
flowchart TB
    U[Client Apps<br/>Web / Mobile / Backend] -->|HTTP: Search / Reverse / Details| LB[API Gateway / Load Balancer]
    LB --> N1[Nominatim API Container #1]
    LB --> N2[Nominatim API Container #2]

    subgraph Data Layer
      PG[(PostgreSQL + PostGIS<br/>Nominatim DB)]
      PV[(Persistent Volume)]
      BK[(Backups: pg_dump / snapshots)]
    end

    N1 --> PG
    N2 --> PG
    PG --> PV
    PG --> BK

    subgraph Import & Updates
      PBF[OSM PBF Source]
      IMP[Initial Import Job]
      DIFF[Replication / Diff Update Job]
    end

    PBF --> IMP --> PG
    DIFF --> PG

    subgraph Performance
      RC[(Redis Cache - optional)]
    end

    N1 <--> RC
    N2 <--> RC

    subgraph Observability
      MET[Prometheus]
      GRA[Grafana]
      LOG[Loki / ELK]
    end

    N1 --> MET
    N2 --> MET
    N1 --> LOG
    N2 --> LOG
    PG --> MET

    subgraph DevOps
      GH[GitHub Repo]
      CI[GitHub Actions CI/CD]
      REG[Container Registry]
    end

    GH --> CI --> REG
    REG --> N1
    REG --> N2
```

---

## 2) Geocoding Sequence Flow (Forward Search)

```mermaid
sequenceDiagram
    autonumber
    participant C as Client App
    participant G as API Gateway / Load Balancer
    participant N as Nominatim API Container
    participant R as Redis Cache (Optional)
    participant P as PostgreSQL + PostGIS
    participant L as Logging / Metrics

    C->>G: GET /search?q=1600+Amphitheatre+Parkway&format=json
    G->>N: Forward request

    N->>L: Increment request counter + start timer
    N->>R: Check cache(key=normalized_query)

    alt Cache hit
        R-->>N: Cached geocoding result
        N->>L: Record cache_hit, latency
        N-->>G: 200 OK + result
        G-->>C: 200 OK + result
    else Cache miss
        R-->>N: Miss
        N->>P: Execute geocoding SQL (text search + ranking + geometry)
        P-->>N: Candidate matches (lat/lon, address, importance)

        alt Results found
            N->>N: Normalize + rank + format response
            N->>R: Store in cache (TTL)
            N->>L: Record db_latency, success, total_latency
            N-->>G: 200 OK + JSON results
            G-->>C: 200 OK + JSON results
        else No results
            N->>L: Record not_found, total_latency
            N-->>G: 200 OK [] / 404 (based on API contract)
            G-->>C: Empty response / Not found
        end
    end

    opt Error path
        N->>L: Record error_type, stack trace, failed query hash
        N-->>G: 5xx error
        G-->>C: 5xx error + retry guidance
    end
```

---

## 3) Core Components

- **Nominatim API containers**: Serve `/search`, `/reverse`, and details endpoints.
- **PostgreSQL + PostGIS**: Stores indexed OSM data and executes geospatial queries.
- **Import/Diff jobs**: Perform initial dataset import and incremental updates.
- **Redis (optional)**: Caches frequent queries to reduce DB load and latency.
- **Observability stack**: Metrics, dashboards, and logs for performance + debugging.

---

## 4) Operational Notes

- Use persistent volumes for database durability.
- Schedule backups (`pg_dump` or volume snapshots).
- Define update cadence for OSM diffs (hourly/daily/weekly depending on use case).
- Add health/readiness checks before exposing service publicly.
- Track P95 latency and error rates for production readiness.

---

## 5) Suggested Future Additions

- **Reverse geocoding sequence** diagram (`/reverse?lat=...&lon=...`)
- **Deployment view** (Docker Compose vs Kubernetes)
- **Failure-mode diagram** (DB unavailable, stale cache, import lag)
