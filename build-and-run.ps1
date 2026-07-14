<# 
.SYNOPSIS
    Build and/or run the Docker image for the uv Python project.

.DESCRIPTION
    This script builds the Docker image using a multi-stage Dockerfile and/or runs the container.
    It supports two modes: Full and Incremental.
    - Full: Builds the image with --no-cache (ignores any cached layers, reinstalls everything).
    - Incremental: Uses Docker's cache to speed up rebuilds (default). Dependencies already
      installed in the image are NOT reinstalled.

    Actions:
    - Build: Only build the image.
    - Run: Only run the container (builds first if the image is missing).
    - BuildAndRun: Build then run (default).

.PARAMETER Action
    Specify the action: 'Build', 'Run', or 'BuildAndRun'. Default is 'BuildAndRun'.

.PARAMETER Mode
    Specify the build mode: 'Full' or 'Incremental'. Default is 'Incremental'.

.EXAMPLE
    .\build-and-run.ps1 -Action Build -Mode Full
    .\build-and-run.ps1 -Action Run -Mode Incremental
    .\build-and-run.ps1  # defaults to BuildAndRun, Incremental
#>

param(
    [ValidateSet('Build', 'Run', 'BuildAndRun')]
    [string]$Action = 'BuildAndRun',

    [ValidateSet('Full', 'Incremental')]
    [string]$Mode = 'Incremental'
)

$imageName = "langchain-in-docker:latest"

function Test-DockerImageExists {
    param([string]$Image)
    try {
        docker image inspect $Image 2>$null | Out-Null
        return $LASTEXITCODE -eq 0
    } catch {
        return $false
    }
}

function Invoke-DockerBuild {
    Write-Host "Building Docker image in $Mode mode..." -ForegroundColor Cyan
    if ($Mode -eq 'Full') {
        docker build -t $imageName --no-cache .
    } else {
        docker build -t $imageName .
    }
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Docker build failed."
        exit 1
    }
    Write-Host "Build successful." -ForegroundColor Green
}

function Invoke-DockerRun {
    if (-not (Test-DockerImageExists $imageName)) {
        Write-Host "Image $imageName not found. Building it first..." -ForegroundColor Yellow
        Invoke-DockerBuild
    }
    Write-Host "Running container..." -ForegroundColor Cyan
    docker run --rm $imageName
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Docker run failed."
        exit 1
    }
}

switch ($Action) {
    'Build'       { Invoke-DockerBuild }
    'Run'         { Invoke-DockerRun }
    'BuildAndRun' {
        Invoke-DockerBuild
        Invoke-DockerRun
    }
}
