## Table of Contents

1. [Introduction](#introduction)
2. [Getting Started](#get-started)
3. [Project Structure](#project-structure)
4. [Models](#models)
5. [API Endpoints](#api-endpoints)
6. [Dependencies](#dependencies)
7. [Error Handling](#error-handling)
8. [Validation](#validation)
9. [Documentation](#documentation)

## Introduction

This style guide provides standards and best practices for developing FastAPI applications using a model-based approach. By following these guidelines, you'll create applications that are:

- Type-safe and self-documenting
- Easy to maintain and extend
- Well-organized with clear separation of concerns
- Consistent across your codebase

## Getting Started ( Optional )

Let's create a vega ( call it whatever you like ) shell function.

1. Edit your `~/.bashrc` or `~/.zshrc` and define vega like this:

```bash
vega() {
  if [[ "$1" == "init" && "$2" == "fastapi" ]]; then
    echo "📥 Downloading scaffold script..."
    curl -sSL https://raw.githubusercontent.com/your-username/vega-scripts/main/init_fastapi.sh | bash
  else
    echo "❌ Usage: vega init fastapi"
  fi
}

```

2.  Reload your shell

```bash
source ~/.bashrc   # or source ~/.zshrc
```

## Project Structure

Organize your FastAPI project with the following directory structure:

```bash
project_root/
├── api
│   ├── .config/
│   │   ├── __init__.py
│   │   ├── settings.py           # App configuration
│   │   ├── db/
│   │   │   ├── __init__.py
│   │   │   └── connection.py     # Database connection handling
│   │   └── security.py           # Security configurations
│	│
│   ├── routers/
│   │   ├── __init__.py
│   │   ├── v1/
│   │   │   ├── __init__.py
│   │   │   ├── dependencies.py
│   │   │   ├── auth.py
│   │   │   └── user.py           # User endpoints
│   │	└── other versions
│   │
│   ├── models/
│   │   ├── __init__.py
│   │   ├── base.py               # Base Pydantic models
│   │   ├── auth.py               # Auth-related models
│   │   └── user.py               # User-related models
│   │
│   ├── schemas/
│   │   ├── __init__.py
│   │   └── base.py               # Base DB models
│   │
│   ├── services/
│   │   ├── __init__.py
│   │   └── user_management.py    # Hanldes user operations eg sign up, sign in etc
│   │
│   ├── utils/
│   │   ├── __init__.py
│   │   └── helper functions
│   │
│   ├── tests/
│   │   ├── __init__.py
│   │   ├── conftest.py
│   │   ├── unit/
│   │   └── integration/
│   │
│   ├── exceptions/
│   │	├── __init__.py
│   │	├── handlers.py               # Custom exception handlers
│   │	└── types.py                  # Custom exception classes
│   │
│   ├── main.py                   	  # Application entry point
│   └── middleware.py                 # Custom middleware
│
├── .env                              # Environment variables
├── requirements.txt                  # Dependencies
└── README.md                         # Project Overview & Starter Docs
```

## Models

By Models we typically refer to two layers.

1. **SQLAlchemy models** – for defining database tables
2. **Pydantic models (schemas)** – for request and response validation

### SQLAlchemy Models

Place SQLAlchemy models in the `api/models/` directory. Use a shared `Base` class from `models/base.py` to standardize metadata and common columns

**For Example:**
Let's say you want to isolate a SQLAlchemy model ( Users ) but want it to share the same metadata ( Constraints & Relationships ). Your code would look something like this.

`models/users.py`

```python
from sqlalchemy import Column, Integer, String
from api.models.base import Base # import base class from api/models/base.py

Class User (Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True)
    email = Column(String, unique=True, index=True)
    hashed_password = Column(String)
```

`models/base.py`

```python
from sqlalchemy.orm import declarative_base

Base = declarative_base ()
```

**Best Practices:**

- Use `snake_case` for table and field names.
- Always define `__tablename__`.
- Avoid business logic[^1] inside models; use service layer ( `api/services` ) for that.
- Use SQLAlchemy types with constraints: `nullable=False`, `unique=True`, et

[^1]: Business logic simply refers to **core rules and operations** that define how an application behaves for example user registration

### Pydantic Models (Schemas)

Place Pydantic models in `api/schemas/`. Use separate models for input (e.g., `UserCreate`) and output (e.g., `UserResponse`) to improve type safety and maintain flexibility.

**Example :**

```python
from pydantic import BaseModel, EmailStr

class UserBase(BaseModel):
    username: str
    email: EmailStr

class UserCreate(UserBase):
    password: str

class UserResponse(UserBase):
    id: int

    class Config:
        orm_mode = True  # Enables SQLAlchemy -> Pydantic conversion

```

**Best Practices:**

- Use `BaseModel` inheritance hierarchies to avoid duplication.
- Use `EmailStr`, `constr`, etc. for precise validation.
- Use `orm_mode = True` only on response models that interface with DB ORM models.
- Keep schemas lean — no business logic or complex methods.

## API Endpoints

API endpoints are the **interface** between clients and your backend logic. In FastAPI, these are typically defined in **routers** organized by version and feature.

### Where to Define Endpoints

Place endpoints in the `api/routers/v1/` directory, grouped by domain (e.g., `auth.py`, `user.py`, etc.).

**Example: `routers/v1/user.py`**

```python
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from api.schemas.user import UserCreate, UserResponse
from api.services.user_management import create_user
from api.routers.v1.dependencies import get_db

router = APIRouter(prefix="/users", tags=["users"])

@router.post("/", response_model=UserResponse, status_code=201)
def register_user(user: UserCreate, db: Session = Depends(get_db)):
    try:
        return create_user(db=db, user_data=user)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

```

### Best Practices

#### Use Versioning

Group endpoints by version (`v1`, `v2`, etc.) to support future changes without breaking old clients.

#### Organize by Feature/Domain

Split routers by logical units like `auth.py`, `user.py`, `product.py`, etc. Avoid putting all endpoints in `main.py`.

#### Use Dependency Injection

Use `Depends()` for shared logic (e.g., database sessions, authentication, permission checks).

#### Return Pydantic Schemas

Always return **response models** for strong typing and automatic documentation:

```python
@router.get("/{user_id}", response_model=UserResponse)
def get_user(user_id: int, db: Session = Depends(get_db)):
    ...

```

#### Use Proper HTTP Methods

| Operation       | Method | Example URL   |
| --------------- | ------ | ------------- |
| Create resource | POST   | `/users/`     |
| Read resource   | GET    | `/users/{id}` |
| Update resource | PUT    | `/users/{id}` |
| Partial update  | PATCH  | `/users/{id}` |
| Delete resource | DELETE | `/users/{id}` |

#### Use Status Codes Explicitly

Set the appropriate status code for each operation using `status_code=`:

```python
@router.delete("/{id}", status_code=204)
```

### Example Directory: `api/routers/v1/`

```bash
v1/
├── __init__.py
├── auth.py           # Login, register, token refresh
├── user.py           # Get, update, delete user
├── dependencies.py   # Shared dependencies
└── product.py        # Example business domain
```

## Dependencies

In FastAPI, **dependencies** are reusable components that can be injected into endpoints using `Depends()`. They help keep your code **clean, modular, and testable**.

---

### Use Cases for Dependencies

- Database session injection
- Authentication and authorization
- Common query parameters
- Reusable service logic (e.g. pagination, filtering)

### Example: Dependency for Database Session

**`api/routers/v1/dependencies.py`**

```python
from sqlalchemy.orm import Session
from api.config.db.connection import SessionLocal

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

```

**In Router**

```python
@router.get("/users/{id}")
def get_user(id: int, db: Session = Depends(get_db)):
    ...

```

**Example: Authenticated User Dependency**

```python
from fastapi import Depends, HTTPException
from api.config.security import verify_token

def get_current_user(token: str = Depends(oauth2_scheme)):
    user = verify_token(token)
    if not user:
        raise HTTPException(status_code=401, detail="Invalid credentials")
    return user
```

Then in your route:

```python
@router.get("/me")
def read_profile(current_user = Depends(get_current_user)):
    return current_user
```

**Best Practices**

| ✅ Do                                                                   | ❌ Avoid                                           |
| ----------------------------------------------------------------------- | -------------------------------------------------- |
| Use dependencies to inject DB, auth, settings, etc.                     | Mixing DB and auth logic in routes directly        |
| Isolate reusable logic in `dependencies.py`                             | Copy-pasting dependency logic across routers       |
| Chain dependencies (e.g., `get_current_user` depends on `verify_token`) | Nesting too many dependencies without reason       |
| Keep dependencies **small and testable**                                | Embedding large business logic inside dependencies |

### Directory Suggestion

Create a dedicated file for reusable dependencies:

```bash
api/
├── routers/
│   ├── v1/
│   │   ├── dependencies.py   # Shared for v1
│   │   ├── auth.py
│   │   └── user.py

```

### Use `HTTPException` for API Errors

Use FastAPI’s built-in `HTTPException` to raise expected HTTP errors:

```python
from fastapi import HTTPException

raise HTTPException(status_code=404, detail="User not found")

```

### Best Practices

| ✅ Do                                                           | ❌ Avoid                                           |
| --------------------------------------------------------------- | -------------------------------------------------- |
| - Use `HTTPException` for known client-side issues              | - Silently swallowing exceptions                   |
| - Define custom exceptions for expected errors                  | - Using string messages everywhere                 |
| - Centralize exception handling in `main.py` or `middleware.py` | - Duplicating `try-except` logic in every endpoint |
| - Log critical errors server-side                               | - Exposing internal stack traces to users          |
|                                                                 |                                                    |

### File Structure For Error Handling Logic

```bash
api/
├── middleware.py               # Optional: global error catching
├── exceptions/
│   ├── __init__.py
│   ├── handlers.py             # Custom exception handlers
│   └── types.py                # Custom exception classes

```

## Validation

Validation in FastAPI is powered by **Pydantic**, which ensures your request and response data is clean, structured, and type-safe. Use Pydantic models to validate incoming payloads & query parameters.

### Best Practices

| ✅ Do                                                     | ❌ Avoid                                   |
| --------------------------------------------------------- | ------------------------------------------ |
| - Use Pydantic models for **every** request and response  | - Accepting raw `dict` s or untyped inputs |
| - Use type constraints: `EmailStr`, `constr`, `conint`    | - Letting user input go unchecked          |
| - Validate query/path parameters with `Query()`, `Path()` | - Manually parsing parameters              |
| - Use `BaseSettings` for env vars                         | - Using `os.getenv()` everywhere           |

## Documentation

FastAPI automatically generates interactive, self-updating documentation using **OpenAPI** and **JSON Schema**. You get two built-in docs:

- **Swagger UI** → `/docs`
- **ReDoc** → `/redoc`

This makes your API easy to explore, test, and integrate with — especially for frontend teams and external developers.

### Making the docs better

1. Use tags on all routes

For example:

```python
@router.get("/users", tags=["Users"])
	def list_users():
```

2. **Document Request and Response Models**

Use `response_model`, `summary`, `description`, and `status_code` for clarity:

```python
@router.post(
    "/users",
    response_model=UserResponse,
    status_code=201,
    summary="Register a new user",
    description="Creates a user and returns basic profile info."
)
def create_user(user: UserCreate):
    ...

```

3.  **Use Examples in Pydantic Models**

For example:

```python
class UserCreate(BaseModel):
    username: str
    email: EmailStr

    class Config:
        schema_extra = {
            "example": {
                "username": "johndoe",
                "email": "johndoe@example.com"
            }
        }

```

### Best Practices

| ✅ Do                                                     | ❌ Avoid                              |
| --------------------------------------------------------- | ------------------------------------- |
| - Use `summary`, `description`, and `tags` for all routes | - Leaving routes undocumented         |
| - Provide example payloads in models                      | - Relying on users to guess structure |
| - Update docs as part of feature work                     | - Letting docs fall out of sync       |
|                                                           |                                       |

## Final Thoughts

With strong organization, clear models, proper validation, dependency injection, and great documentation, a FastAPI app will be maintainable, secure, and developer-friendly.
