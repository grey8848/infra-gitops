# DOCKER (LOCAL DEV UTILITIES) — AGENTS

## OVERVIEW
Local development utilities. `docker/flinkcdc/` contains build inputs for a Flink CDC image. `docker/nacos/` is a Podman Compose setup for Nacos; runtime state lives under `docker/nacos/data/` and `docker/nacos/logs/`.

## STRUCTURE
```
docker/
├── flinkcdc/                 # Flink CDC image build inputs (Dockerfile + templates)
└── nacos/                    # Nacos via podman-compose (README + compose)
    ├── data/                 # runtime state (do not commit)
    └── logs/                 # runtime logs (do not commit)
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| Build Flink CDC image | `docker/flinkcdc/Dockerfile` | JARs are expected locally; they are gitignored. |
| CDC pipeline config template | `docker/flinkcdc/pipeline.yaml` | Uses Helm-style templating (`.Values.cdc.*`). |
| CDC SQL template | `docker/flinkcdc/job.sql` | Uses Helm-style templating (`.Values.cdc.*`). |
| Run Nacos locally | `docker/nacos/README.md` | Uses `podman-compose` / `podman compose`. |

## CONVENTIONS
- Do not commit runtime state from `docker/nacos/` (`data/`, `logs/`, `.env.nacos`). The local `.gitignore` in that folder enforces this.
- `docker/flinkcdc/` JAR dependencies are intentionally ignored (see repo root `.gitignore`).

## COMMANDS
```bash
# Nacos (Podman)
cd docker/nacos
cp .env.nacos.example .env.nacos
podman-compose up -d

# Flink CDC image build (requires local JARs in docker/flinkcdc/)
docker build -t local-registry:5000/flink-cdc:<tag> docker/flinkcdc
```
