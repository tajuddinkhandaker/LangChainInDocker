# Stage 0: Builder
FROM python:3.12-slim AS builder

# Install uv
RUN pip install uv

# Set workdir
WORKDIR /app

# Copy pyproject.toml (dependencies declared here)
COPY pyproject.toml pyproject.toml

# Tell uv to use our specific venv path for the project environment
ENV UV_PROJECT_ENVIRONMENT=/root/.venv

# Create virtual environment and install all dependencies from pyproject.toml via uv sync
# --no-install-project skips building the demo package itself (no uv.build needed)
RUN uv venv /root/.venv && \
    uv sync --no-dev --no-install-project

# Stage 1: Runtime
FROM python:3.12-slim AS runtime

# Copy the virtual environment from builder
COPY --from=builder /root/.venv /venv

# Add venv to PATH
ENV PATH="/venv/bin:$PATH"

# Set workdir
WORKDIR /app

# Copy application code
COPY app.py .

# Default command
CMD ["python", "app.py"]