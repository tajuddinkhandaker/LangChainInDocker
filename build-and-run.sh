#!/bin/bash

# Build and/or run the Docker image for the uv Python project.
# Supports two modes: Full and Incremental.
# - Full: Builds the image with --no-cache (ignores any cached layers, reinstalls everything).
# - Incremental: Uses Docker's cache to speed up rebuilds (default). Dependencies already
#   installed in the image are NOT reinstalled.
#
# Actions:
# - build: Only build the image.
# - run: Only run the container (builds first if the image is missing).
# - build-and-run: Build then run (default).
#
# Usage: ./build-and-run.sh [build|run|build-and-run] [Full|Incremental]

ACTION="${1:-build-and-run}"
MODE="${2:-Incremental}"

# Validate action
if [[ "$ACTION" != "build" && "$ACTION" != "run" && "$ACTION" != "build-and-run" ]]; then
    echo "Error: Action must be 'build', 'run', or 'build-and-run'"
    echo "Usage: $0 [build|run|build-and-run] [Full|Incremental]"
    exit 1
fi

# Validate mode
if [[ "$MODE" != "Full" && "$MODE" != "Incremental" ]]; then
    echo "Error: Mode must be 'Full' or 'Incremental'"
    echo "Usage: $0 [build|run|build-and-run] [Full|Incremental]"
    exit 1
fi

imageName="langchain-in-docker:latest"

function docker_image_exists() {
    docker image inspect "$1" >/dev/null 2>&1
}

function docker_build() {
    echo "Building Docker image in $MODE mode..."
    if [[ "$MODE" == "Full" ]]; then
        docker build -t "$imageName" --no-cache .
    else
        docker build -t "$imageName" .
    fi
    if [[ $? -ne 0 ]]; then
        echo "Error: Docker build failed."
        exit 1
    fi
    echo "Build successful."
}

function docker_run() {
    if ! docker_image_exists "$imageName"; then
        echo "Image $imageName not found. Building it first..."
        docker_build
    fi
    echo "Running container..."
    docker run --rm "$imageName"
    if [[ $? -ne 0 ]]; then
        echo "Error: Docker run failed."
        exit 1
    fi
}

case "$ACTION" in
    build)
        docker_build
        ;;
    run)
        docker_run
        ;;
    build-and-run)
        docker_build
        docker_run
        ;;
esac