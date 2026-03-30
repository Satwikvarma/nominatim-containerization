# How to improve this container setup

The current repository keeps the container minimal (Ubuntu + PostGIS + Nominatim sources) so you can inspect and experiment. To move toward a production-ready or fully functional Nominatim deployment, consider the steps below.

## 1) Automate data import
- Download a PBF extract (e.g., Geofabrik) during build or on first run.
- Run the Nominatim import pipeline inside the container:
  - `nominatim import --osm-file <path-to-pbf>` (for legacy 3.x installs this was done via `setup.php`, but 4.x+ uses the `nominatim` CLI).
- Cache the import output in a Docker volume so you do not have to re-import on every container start.

## 2) Persist PostgreSQL data
- Mount a named Docker volume for Postgres data (e.g., `/var/lib/postgresql/data`).
- Add a health check for Postgres so the Nominatim service only starts after the database is ready.

## 3) Run as a non-root user
- Create an unprivileged user in the Dockerfile.
- Adjust file permissions for the cloned Nominatim source and Postgres directories.

## 4) Expose and document ports
- Expose the HTTP port used by Nominatim’s web service (commonly 8080).
- Add a reverse proxy (Caddy/NGINX) if you plan to deploy behind TLS.

## 5) Compose enhancements
- Extend `docker-compose.yml` with a dedicated Postgres/PostGIS service instead of running everything in a single container.
- Add environment variables for locale, memory, and tuning parameters.
- Include a simple `healthcheck` to know when the service is ready.

## 6) Observability and maintenance
- Add basic logs/metrics shipping (e.g., bind-mounted log path, Prometheus exporter).
- Document backup/restore steps for the Postgres volume.

## 7) CI/CD tightening
- Add a basic CI job that builds the image and runs a smoke test (e.g., `nominatim --version` and a simple HTTP check after `docker compose up`).
- Push signed images to your registry using the existing `docker-publish` workflow as a base.

Start with import automation and persistent volumes—these will give the biggest usability boost without making the setup overly complex.
