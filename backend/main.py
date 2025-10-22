from flask import Flask, jsonify, request
from flask_cors import CORS
from datetime import datetime
import uuid

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# In-memory data storage (for demo purposes)
products = [
    {"id": "1", "name": "Laptop", "price": 999.99, "category": "Electronics"},
    {"id": "2", "name": "Book", "price": 19.99, "category": "Education"},
    {"id": "3", "name": "Coffee Mug", "price": 12.99, "category": "Home"},
]

users = [
    {"id": "1", "name": "John Doe", "email": "john@example.com"},
    {"id": "2", "name": "Jane Smith", "email": "jane@example.com"},
]

@app.route('/', methods=['GET'])
def home():
    """Welcome endpoint"""
    return jsonify({
        "message": "Welcome to the Simple E-commerce API",
        "version": "1.0.0",
        "timestamp": datetime.now().isoformat()
    })

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        "status": "healthy",
        "timestamp": datetime.now().isoformat()
    })

# Product endpoints
@app.route('/api/products', methods=['GET'])
def get_products():
    """Get all products"""
    return jsonify({
        "success": True,
        "data": products,
        "count": len(products)
    })

@app.route('/api/products/<product_id>', methods=['GET'])
def get_product(product_id):
    """Get a specific product by ID"""
    product = next((p for p in products if p["id"] == product_id), None)
    if product:
        return jsonify({
            "success": True,
            "data": product
        })
    return jsonify({
        "success": False,
        "error": "Product not found"
    }), 404

@app.route('/api/products', methods=['POST'])
def create_product():
    """Create a new product"""
    data = request.get_json()
    
    if not data or not all(k in data for k in ('name', 'price', 'category')):
        return jsonify({
            "success": False,
            "error": "Missing required fields: name, price, category"
        }), 400
    
    new_product = {
        "id": str(uuid.uuid4()),
        "name": data["name"],
        "price": float(data["price"]),
        "category": data["category"]
    }
    
    products.append(new_product)
    
    return jsonify({
        "success": True,
        "data": new_product,
        "message": "Product created successfully"
    }), 201

@app.route('/api/products/<product_id>', methods=['PUT'])
def update_product(product_id):
    """Update an existing product"""
    data = request.get_json()
    product = next((p for p in products if p["id"] == product_id), None)
    
    if not product:
        return jsonify({
            "success": False,
            "error": "Product not found"
        }), 404
    
    # Update product fields if provided
    if 'name' in data:
        product['name'] = data['name']
    if 'price' in data:
        product['price'] = float(data['price'])
    if 'category' in data:
        product['category'] = data['category']
    
    return jsonify({
        "success": True,
        "data": product,
        "message": "Product updated successfully"
    })

@app.route('/api/products/<product_id>', methods=['DELETE'])
def delete_product(product_id):
    """Delete a product"""
    global products
    initial_count = len(products)
    products = [p for p in products if p["id"] != product_id]
    
    if len(products) < initial_count:
        return jsonify({
            "success": True,
            "message": "Product deleted successfully"
        })
    
    return jsonify({
        "success": False,
        "error": "Product not found"
    }), 404

# User endpoints
@app.route('/api/users', methods=['GET'])
def get_users():
    """Get all users"""
    return jsonify({
        "success": True,
        "data": users,
        "count": len(users)
    })

@app.route('/api/users/<user_id>', methods=['GET'])
def get_user(user_id):
    """Get a specific user by ID"""
    user = next((u for u in users if u["id"] == user_id), None)
    if user:
        return jsonify({
            "success": True,
            "data": user
        })
    return jsonify({
        "success": False,
        "error": "User not found"
    }), 404

@app.route('/api/users', methods=['POST'])
def create_user():
    """Create a new user"""
    data = request.get_json()
    
    if not data or not all(k in data for k in ('name', 'email')):
        return jsonify({
            "success": False,
            "error": "Missing required fields: name, email"
        }), 400
    
    new_user = {
        "id": str(uuid.uuid4()),
        "name": data["name"],
        "email": data["email"]
    }
    
    users.append(new_user)
    
    return jsonify({
        "success": True,
        "data": new_user,
        "message": "User created successfully"
    }), 201

# Error handlers
@app.errorhandler(404)
def not_found(error):
    return jsonify({
        "success": False,
        "error": "Endpoint not found"
    }), 404

@app.errorhandler(500)
def internal_error(error):
    return jsonify({
        "success": False,
        "error": "Internal server error"
    }), 500

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)