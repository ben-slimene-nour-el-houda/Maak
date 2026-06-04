#!/usr/bin/env bash
set -e

echo "Starting local backend with Docker Compose..."
docker-compose up --build

echo "Backend is available at http://localhost:8000"
echo "Run the Flutter app separately with: flutter run"
