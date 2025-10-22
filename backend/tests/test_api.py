import pytest
import sys
import os

# Add the backend directory to the Python path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from main import app

@pytest.fixture
def client():
    """Create a test client for the Flask app."""
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_health_endpoint(client):
    """Test the health check endpoint."""
    response = client.get('/health')
    assert response.status_code == 200
    data = response.get_json()
    assert data['status'] == 'healthy'

def test_get_products(client):
    """Test retrieving all products."""
    response = client.get('/api/products')
    assert response.status_code == 200
    data = response.get_json()
    assert isinstance(data, list)

def test_create_product(client):
    """Test creating a new product."""
    product_data = {
        'name': 'Test Product',
        'price': 29.99,
        'description': 'A test product'
    }
    response = client.post('/api/products', json=product_data)
    assert response.status_code == 201
    data = response.get_json()
    assert data['name'] == 'Test Product'
    assert data['price'] == 29.99

def test_get_users(client):
    """Test retrieving all users."""
    response = client.get('/api/users')
    assert response.status_code == 200
    data = response.get_json()
    assert isinstance(data, list)

def test_create_user(client):
    """Test creating a new user."""
    user_data = {
        'name': 'Test User',
        'email': 'test@example.com'
    }
    response = client.post('/api/users', json=user_data)
    assert response.status_code == 201
    data = response.get_json()
    assert data['name'] == 'Test User'
    assert data['email'] == 'test@example.com'

def test_cors_headers(client):
    """Test that CORS headers are present."""
    response = client.get('/api/products')
    assert 'Access-Control-Allow-Origin' in response.headers