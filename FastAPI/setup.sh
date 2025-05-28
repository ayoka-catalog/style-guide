#!/bin/bash

# Exit on error
set -e

read -p "Enter project name: " PROJECT_NAME

# Create the root project folder
mkdir -p $PROJECT_NAME
cd $PROJECT_NAME || exit

echo "Setting up project structure..."

# Base files
touch .env
echo "# Python dependencies" > requirements.txt
echo "# FastAPI Project Starter" > README.md

# Virtual Environment
echo "Creating virtual environment..."
python3 -m venv venv
source venv/bin/activate

# Install core dependencies
echo "Installing FastAPI and Uvicorn..."
pip install --upgrade pip
pip install fastapi uvicorn[standard]
pip freeze > requirements.txt

# Entry point
mkdir -p api
cat <<EOF > api/main.py
from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def root():
    return {"message": "Welcome to your FastAPI app!"}
EOF

# Middleware
echo "# Custom middleware (CORS, Logging, etc.)" > api/middleware.py

# Config
mkdir -p api/.config/db
touch api/.config/__init__.py
echo "# App configuration settings" > api/.config/settings.py
echo "# Database connection handling" > api/.config/db/connection.py
echo "# Security configurations (JWT, Password Hashing)" > api/.config/security.py

# Routers
mkdir -p api/routers/v1
touch api/routers/__init__.py
touch api/routers/v1/__init__.py
echo "# Shared route dependencies (e.g., auth)" > api/routers/v1/dependencies.py
echo "# Auth endpoints: login, token, register" > api/routers/v1/auth.py
echo "# User-related endpoints (CRUD)" > api/routers/v1/user.py

# Models
mkdir -p api/models
touch api/models/__init__.py
echo "# Base Pydantic models (shared schemas)" > api/models/base.py
echo "# Auth-related models (Login, Token)" > api/models/auth.py
echo "# User-related models (UserInDB, Profile)" > api/models/user.py

# Schemas
mkdir -p api/schemas
touch api/schemas/__init__.py
echo "# Base DB models for ORM mapping" > api/schemas/base.py

# Services
mkdir -p api/services
touch api/services/__init__.py
echo "# Business logic for user operations (signup, login)" > api/services/user_management.py

# Utils
mkdir -p api/utils
touch api/utils/__init__.py
echo "# Helper functions, constants, formatting, etc." > api/utils/helpers.py

# Tests
mkdir -p api/tests/unit
mkdir -p api/tests/integration
touch api/tests/__init__.py
echo "# Pytest shared fixtures (e.g., test client)" > api/tests/conftest.py

# Success message
echo "FastAPI project setup complete!"

echo "To run the app: cd $PROJECT_NAME && source venv/bin/activate && uvicorn api.main:app --reload"

