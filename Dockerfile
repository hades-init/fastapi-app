# --------- Stage 1: Builder ---------

# The official Docker image for Python3.12 with uv pre-installed
FROM astral/uv:python3.12-bookworm-slim AS builder

# Set environment variables for uv
#   UV_COMPILE_BYTECODE=1   -> precompile Python source files to bytecode (cached .pyc files) at install time (faster cold start)
#   UV_LINK_MODE=copy       -> avoid hardlink warnings across layers/volumes
#   UV_PYTHON_DOWNLOADS=0   -> use the python that's already in the base image
ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_PYTHON_DOWNLOADS=0

# Change the working directory to the `app` directory
WORKDIR /app

# Install dependencies, first in their own layer, so changes to your 
# source code don't slow dependency-install (layers are cached).
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --locked --no-install-project


# Now copy the application source and install the project
COPY . .
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --locked --no-dev



# --------- Stage 2: Runtime ---------

# Slim runtime image -- no uv, no build toolchain, just python + your venv
FROM python:3.12-slim-bookworm AS runtime

# Setup a non-root user
RUN groupadd appgroup && useradd -g appgroup -s /bin/bash -m appuser
# which is equivalent to running,
# RUN groupadd appgroup \
    # && useradd --gid appgroup --shell /bin/bash --create-home appuser

# Copy the resolved venv and the application code from the builder stage.
COPY --from=builder --chown=appuser:appgroup /app /app

# Place executables in the environment at the front of the path
#   PYTHONDONTWRITEBYTECODE=1 ->  don't write .pyc at runtime (we already did in builder)
#   PYTHONUNBUFFERED=1        ->  flush stdout/stderr immediately (proper docker logs)
#   PATH includes the venv so `gunicorn`, `alembic`, etc. resolve directly
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/app/.venv/bin:$PATH"

# Use the non-root user to run our application
USER appuser

# Use `/app` as the working directory
WORKDIR /app

# The container will listen on port 8000 (only for documentation, port binding is in `compose.yml`)
EXPOSE 8000

# Run the FastAPI application by default
CMD ["gunicorn", "app.main:app", "-c", "gunicorn.conf.py"]