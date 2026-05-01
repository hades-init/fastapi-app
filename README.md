# FastAPI Social Media API

A social media REST API built with FastAPI and PostgreSQL. Users can register and log in, create and delete posts, and vote on posts they like. It's a fairly standard CRUD API — that will allow you to get hands-on with FastAPI, SQLAlchemy, and JWT authentication, and to practice deploying a containerized Python app to a Linux server.

The API is documented with Swagger UI out of the box at [`http://localhost:8000/docs`](http://localhost:8000/docs).

## Features

- **Users** — register and authenticate with JWT access tokens
- **Posts** — create, read, update, and delete posts
- **Votes** — like / unlike posts; vote counts returned with each post

<img width="1890" height="1245" alt="Screenshot 2026-05-01 at 8 39 35 PM" src="https://github.com/user-attachments/assets/5f7de5d6-5bbc-4cea-81f4-f6b25bfd2f2f" />


## Tech Stack

- **Python** 3.12
- **FastAPI** — web framework
- **SQLAlchemy** + **Alembic** — ORM and database migrations
- **PostgreSQL** 16 — database
- **Gunicorn** + **Uvicorn workers** — application server and workers management
- **uv** — dependency management
- **Docker** + **Docker Compose** — containerization
- **Nginx** — reverse proxy and SSL/TLS termination

## Project Structure

```
.
├── app/                    # Application source
│   ├── core/               # Config, database, settings
│   ├── routes/             # API route handlers
│   ├── main.py             # FastAPI app entrypoint
│   ├── models.py           # SQLAlchemy models
│   ├── schemas.py          # Pydantic schemas
│   └── utils.py
├── alembic/                # Database migration scripts
├── ubuntu-vm-conf/         # VM-side config (systemd unit, nginx)
├── Dockerfile              # Multi-stage build (uv builder + slim runtime)
├── compose.yml             # Compose stack: api + postgres
├── gunicorn.conf.py        # Gunicorn worker config
├── pyproject.toml          # Project metadata and dependencies
└── uv.lock                 # Locked dependency versions
```

## Installation

Requires Python 3.12 and [uv](https://docs.astral.sh/uv/).

```bash
% git clone <repo-url> && cd fastapi
% cp .env.template .env          # set POSTGRES_PASSWORD and SECRET_KEY in `.env` file
% uv sync                        # install dependencies
% uv run alembic upgrade head    # run migrations
```

Generate a secret key with `openssl rand -hex 32`.

## Running locally

```bash
uv run fastapi dev app.main:app
```

Automatic SwaggerUI documentation available at <http://localhost:8000/docs>.

## Running with Docker

This is the recommended way — spins up the app and PostgreSQL together (asuming docker is installed):
```bash
% docker compose up -d --build
% curl -i http://127.0.0.1:8000/health-check   # health-check
% docker compose logs -f api                   # fastapi server logs
% docker compose logs -f postgres              # postgresql logs
```

Migrations run automatically on startup. To stop container use command `docker compose down`. To stop continer and wipe the database: `docker compose down -v`.

## Deployment

The app can be run on an Ubuntu VM behind Nginx with SSL/TLS termination. Docker Compose manages the containers; a systemd unit ensures they start on reboot.

**One-time setup on the VM:**

Replace `<your-user>` and `<user-group>` placeholders in the conf files with your non-root linux user and group.

```bash
# Install Docker
% curl -fsSL https://get.docker.com | sh
% sudo usermod -aG docker $USER

# Install Nginx + Certbot
% sudo apt install nginx certbot python3-certbot-nginx

# Clone and configure
% git clone <repo-url> && cd fastapi
% cp .env.template .env && chmod 600 .env   # set variables in `.env` file

# Enable the site in Nginx, 
% sudo cp ubuntu-vm-conf/nginx-conf /etc/nginx/sites-available/<your-domain>    # configure reverse proxy  
% sudo ln -s /etc/nginx/sites-available/<your-domain> /etc/nginx/sites-enabled/
% sudo nginx -t && sudo systemctl reload nginx   # verify nginx configurations and reload      

# SSL temination (DNS must already point at the VM)
% sudo certbot --nginx -d <your-domain>

# Auto-start on reboot
% sudo cp ubuntu-vm-conf/app.docker.conf /etc/systemd/system/fastapi-app.service
% sudo systemctl daemon-reload
% sudo systemctl enable --now fastapi-app.service
```

**Deploying updates:**

```bash
git pull && docker compose up -d --build
```

## Configuration

All runtime configuration is read from environment variables (loaded from `.env` by Docker Compose, or by `pydantic-settings` in local development). See `.env.template` for the full list:

| Variable | Description |
|---|---|
| `ENVIRONMENT` | `local`, `staging`, or `production` |
| `POSTGRES_SERVER` | Database host (`localhost` for local dev; overridden to `postgres` in compose) |
| `POSTGRES_PORT` | Database port |
| `POSTGRES_USER` | Database user |
| `POSTGRES_PASSWORD` | Database password |
| `POSTGRES_DB` | Database name |
| `SECRET_KEY` | JWT signing secret. Generate with `openssl rand -hex 32` |
