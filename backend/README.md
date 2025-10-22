# Simple E-commerce API

A simple REST API built with Flask for managing products and users.

## Features

- **Products Management**: Create, read, update, and delete products
- **Users Management**: Create and read users
- **CORS Support**: Cross-origin requests enabled
- **JSON Responses**: All endpoints return JSON formatted responses
- **Error Handling**: Proper HTTP status codes and error messages

## Endpoints

### General

- `GET /` - Welcome message
- `GET /health` - Health check

### Products

- `GET /api/products` - Get all products
- `GET /api/products/<id>` - Get a specific product
- `POST /api/products` - Create a new product
- `PUT /api/products/<id>` - Update a product
- `DELETE /api/products/<id>` - Delete a product

### Users

- `GET /api/users` - Get all users
- `GET /api/users/<id>` - Get a specific user
- `POST /api/users` - Create a new user

## Installation

1. Install dependencies:

   ```bash
   pip install -r requirements.txt
   ```

2. Run the API:
   ```bash
   python main.py
   ```

The API will be available at `http://localhost:5000`

## Example Usage

### Create a Product

```bash
curl -X POST http://localhost:5000/api/products \
  -H "Content-Type: application/json" \
  -d '{"name": "New Product", "price": 29.99, "category": "Electronics"}'
```

### Get All Products

```bash
curl http://localhost:5000/api/products
```

### Create a User

```bash
curl -X POST http://localhost:5000/api/users \
  -H "Content-Type: application/json" \
  -d '{"name": "Alice Johnson", "email": "alice@example.com"}'
```

## Sample Data

The API comes with sample products and users for testing purposes.
