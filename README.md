# LangChain in Docker

A demonstration project showing how to manage Python dependencies with **uv** and build optimized Docker images using multi-stage builds. Includes cross-platform build scripts for Windows (PowerShell) and Linux/macOS (Bash).

## Features

- **Fast Dependency Management**: Uses `uv` for 10-100x faster package installation
- **Multi-Stage Docker Build**: Separates build-time and runtime environments for minimal image size
- **Cross-Platform Scripts**: PowerShell (Windows) and Bash (Linux/macOS) scripts
- **Incremental Builds**: Docker layer caching avoids reinstalling unchanged dependencies
- **Flexible Operations**: Build only, run only, or build-and-run in one command

## Project Structure

```
langchain-in-docker/
├── app.py                 # Sample Python application using LangChain
├── Dockerfile             # Multi-stage Docker build
├── pyproject.toml         # Project configuration for uv
├── build-and-run.ps1      # Windows PowerShell build/run script
├── build-and-run.sh       # Linux/macOS Bash build/run script
├── README.md              # This file
└── .dockerignore          # Optional: exclude unnecessary files from build context
```

## Quick Start

### Windows (PowerShell)

```powershell
# Navigate to project directory
cd langchain-in-docker

# Full build and run (no cache)
.\build-and-run.ps1 -Action BuildAndRun -Mode Full

# Incremental build and run (uses cache, default)
.\build-and-run.ps1

# Build only
.\build-and-run.ps1 -Action Build

# Run only (builds if image missing)
.\build-and-run.ps1 -Action Run
```

### Linux/macOS (Bash)

```bash
# Navigate to project directory
cd langchain-in-docker

# Make script executable (first time only)
chmod +x build-and-run.sh

# Full build and run (no cache)
./build-and-run.sh build-and-run Full

# Incremental build and run (uses cache, default)
./build-and-run.sh

# Build only
./build-and-run.sh build

# Run only (builds if image missing)
./build-and-run.sh run
```

## Script Reference

### PowerShell Script (`build-and-run.ps1`)

| Parameter | Values | Default | Description |
|-----------|--------|---------|-------------|
| `-Action` | `Build`, `Run`, `BuildAndRun` | `BuildAndRun` | Operation to perform |
| `-Mode` | `Full`, `Incremental` | `Incremental` | Build mode |

**Examples:**
```powershell
# Full rebuild from scratch
.\build-and-run.ps1 -Action Build -Mode Full

# Incremental build (default)
.\build-and-run.ps1 -Action Build

# Run existing container
.\build-and-run.ps1 -Action Run

# Full build and run
.\build-and-run.ps1 -Action BuildAndRun -Mode Full
```

### Bash Script (`build-and-run.sh`)

```bash
./build-and-run.sh [ACTION] [MODE]
```

| Argument | Values | Default | Description |
|----------|--------|---------|-------------|
| `ACTION` | `build`, `run`, `build-and-run` | `build-and-run` | Operation to perform |
| `MODE` | `Full`, `Incremental` | `Incremental` | Build mode |

**Examples:**
```bash
# Full rebuild from scratch
./build-and-run.sh build Full

# Incremental build (default)
./build-and-run.sh build

# Run existing container
./build-and-run.sh run

# Full build and run
./build-and-run.sh build-and-run Full

# Default (incremental build-and-run)
./build-and-run.sh
```

## Dependency Management

### Adding New Packages

1. **Add to `pyproject.toml`**:
   ```toml
   [project]
   dependencies = [
       "langchain",
       # ...other dependencies
   ]
   ```

2. **Rebuild image** (no need to modify Dockerfile):
   ```bash
   ./build-and-run.sh build-and-run Full
   ```

### Why This Approach?

- **Single Source of Truth**: All dependencies are declared in `pyproject.toml`
- **Reproducible Builds**: Use `uv lock` for deterministic dependency resolution
- **Faster Incremental Builds**: Docker cache invalidates only when `pyproject.toml` changes
- **Consistent Local/Dev Environments**: Same `uv` commands work locally and in Docker

## Dockerfile Details

### Multi-Stage Build

```dockerfile
# Stage 0: Builder
FROM python:3.12-slim AS builder

# Install uv
RUN pip install uv

WORKDIR /app

# Copy dependency manifest
COPY pyproject.toml pyproject.toml

# Create virtual environment and install dependencies
RUN uv venv /root/.venv && \
    uv sync --no-dev --no-install-project

# Stage 1: Runtime
FROM python:3.12-slim AS runtime

# Copy virtual environment from builder
COPY --from=builder /root/.venv /venv

# Add venv to PATH
ENV PATH="/venv/bin:$PATH"

WORKDIR /app

# Copy application code
COPY app.py .

CMD ["python", "app.py"]
```

**Benefits:**
- Build stage has build tools (`uv`, `pip`)
- Runtime stage only has the virtual environment (~50MB vs ~500MB)
- No build tools in final image (security best practice)
- Optimal layer caching

## Sample Application

The included `app.py` demonstrates LangChain usage:

```python
from langchain_core.messages import HumanMessage

print("Hello from Python application running in Docker!")
print("Demonstrating LangChain usage.")
msg = HumanMessage(content="Hello LangChain!")
print(f"Message: {msg.content}")
```

Output:
```
Hello from Python application running in Docker!
Demonstrating LangChain usage.
Message: Hello LangChain!
```

## Troubleshooting

### Docker Build Fails

**Issue**: `uv: command not found`
- **Fix**: Ensure `pip install uv` runs in builder stage

**Issue**: `No module named 'langchain_core'`
- **Fix**: Verify `pyproject.toml` contains `langchain` in dependencies
- Check that `uv sync` completed successfully

**Issue**: `ModuleNotFoundError` at runtime
- **Fix**: Ensure `COPY --from=builder /root/.venv /venv` and `ENV PATH="/venv/bin:$PATH"` are correct

### Scripts Not Executable (Linux/macOS)

```bash
chmod +x build-and-run.sh
```

### PowerShell Execution Policy (Windows)

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

### Image Not Found on Run

The scripts automatically build if the image is missing. To force rebuild:
```powershell
# Windows
.\build-and-run.ps1 -Action Build -Mode Full

# Linux/macOS
./build-and-run.sh build Full
```

## Performance Tips

1. **Use `.dockerignore`** to exclude unnecessary files from build context
2. **Order Dockerfile layers** from least to most frequently changing
3. **Pin base image digest** for reproducible builds:
   ```dockerfile
   FROM python:3.12-slim@sha256:...
   ```
4. **Use BuildKit** for faster builds:
   ```bash
   DOCKER_BUILDKIT=1 docker build ...
   ```

## License

MIT License - Feel free to use this as a template for your projects.

## Resources

- [uv Documentation](https://docs.astral.sh/uv/)
- [Docker Multi-Stage Builds](https://docs.docker.com/build/building/multi-stage/)
- [LangChain Documentation](https://python.langchain.com/)
- [Python Packaging Guide](https://packaging.python.org/)