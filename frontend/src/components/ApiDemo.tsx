import React, { useState } from 'react';
import {
  useProducts,
  useUsers,
  useCreateProduct,
  useCreateUser,
  useApiHealth,
  type CreateProductRequest,
  type CreateUserRequest,
} from '../api';

const ApiDemo: React.FC = () => {
  const {
    data: products,
    loading: productsLoading,
    error: productsError,
    refetch: refetchProducts,
  } = useProducts();
  const {
    data: users,
    loading: usersLoading,
    error: usersError,
    refetch: refetchUsers,
  } = useUsers();
  const {
    data: healthData,
    loading: healthLoading,
    error: healthError,
  } = useApiHealth();

  const { createProduct, loading: createProductLoading } = useCreateProduct();
  const { createUser, loading: createUserLoading } = useCreateUser();

  const [newProduct, setNewProduct] = useState<CreateProductRequest>({
    name: '',
    price: 0,
    category: '',
  });

  const [newUser, setNewUser] = useState<CreateUserRequest>({
    name: '',
    email: '',
  });

  const handleCreateProduct = async (e: React.FormEvent) => {
    e.preventDefault();
    const result = await createProduct(newProduct);
    if (result) {
      setNewProduct({ name: '', price: 0, category: '' });
      refetchProducts();
    }
  };

  const handleCreateUser = async (e: React.FormEvent) => {
    e.preventDefault();
    const result = await createUser(newUser);
    if (result) {
      setNewUser({ name: '', email: '' });
      refetchUsers();
    }
  };

  return (
    <div style={{ padding: '20px', fontFamily: 'Arial, sans-serif' }}>
      <h1>E-commerce API Demo</h1>

      {/* API Health Status */}
      <section
        style={{
          marginBottom: '30px',
          padding: '20px',
          border: '1px solid #ddd',
          borderRadius: '8px',
        }}
      >
        <h2>API Health Status</h2>
        {healthLoading ? (
          <p>Checking API health...</p>
        ) : healthError ? (
          <p style={{ color: 'red' }}>Error: {healthError}</p>
        ) : healthData ? (
          <div>
            <p style={{ color: 'green' }}>Status: {healthData.status}</p>
            <p>Timestamp: {new Date(healthData.timestamp).toLocaleString()}</p>
          </div>
        ) : (
          <p>No health data available</p>
        )}
      </section>

      {/* Products Section */}
      <section
        style={{
          marginBottom: '30px',
          padding: '20px',
          border: '1px solid #ddd',
          borderRadius: '8px',
        }}
      >
        <h2>Products</h2>

        {/* Create Product Form */}
        <form onSubmit={handleCreateProduct} style={{ marginBottom: '20px' }}>
          <h3>Create New Product</h3>
          <div style={{ marginBottom: '10px' }}>
            <input
              type="text"
              placeholder="Product Name"
              value={newProduct.name}
              onChange={(e) =>
                setNewProduct({ ...newProduct, name: e.target.value })
              }
              style={{ margin: '5px', padding: '8px', width: '200px' }}
              required
            />
            <input
              type="number"
              placeholder="Price"
              step="0.01"
              value={newProduct.price}
              onChange={(e) =>
                setNewProduct({
                  ...newProduct,
                  price: parseFloat(e.target.value) || 0,
                })
              }
              style={{ margin: '5px', padding: '8px', width: '100px' }}
              required
            />
            <input
              type="text"
              placeholder="Category"
              value={newProduct.category}
              onChange={(e) =>
                setNewProduct({ ...newProduct, category: e.target.value })
              }
              style={{ margin: '5px', padding: '8px', width: '150px' }}
              required
            />
          </div>
          <button
            type="submit"
            disabled={createProductLoading}
            style={{
              padding: '8px 16px',
              backgroundColor: '#007bff',
              color: 'white',
              border: 'none',
              borderRadius: '4px',
              cursor: createProductLoading ? 'not-allowed' : 'pointer',
            }}
          >
            {createProductLoading ? 'Creating...' : 'Create Product'}
          </button>
        </form>

        {/* Products List */}
        {productsLoading ? (
          <p>Loading products...</p>
        ) : productsError ? (
          <p style={{ color: 'red' }}>Error: {productsError}</p>
        ) : products ? (
          <div>
            <h3>Products List ({products.length})</h3>
            {products.length === 0 ? (
              <p>No products found</p>
            ) : (
              <div style={{ display: 'grid', gap: '10px' }}>
                {products.map((product) => (
                  <div
                    key={product.id}
                    style={{
                      padding: '10px',
                      border: '1px solid #eee',
                      borderRadius: '4px',
                      backgroundColor: '#f9f9f9',
                    }}
                  >
                    <strong>{product.name}</strong> - $
                    {product.price.toFixed(2)}
                    <br />
                    <small>
                      Category: {product.category} | ID: {product.id}
                    </small>
                  </div>
                ))}
              </div>
            )}
          </div>
        ) : (
          <p>No product data available</p>
        )}
      </section>

      {/* Users Section */}
      <section
        style={{
          padding: '20px',
          border: '1px solid #ddd',
          borderRadius: '8px',
        }}
      >
        <h2>Users</h2>

        {/* Create User Form */}
        <form onSubmit={handleCreateUser} style={{ marginBottom: '20px' }}>
          <h3>Create New User</h3>
          <div style={{ marginBottom: '10px' }}>
            <input
              type="text"
              placeholder="User Name"
              value={newUser.name}
              onChange={(e) => setNewUser({ ...newUser, name: e.target.value })}
              style={{ margin: '5px', padding: '8px', width: '200px' }}
              required
            />
            <input
              type="email"
              placeholder="Email"
              value={newUser.email}
              onChange={(e) =>
                setNewUser({ ...newUser, email: e.target.value })
              }
              style={{ margin: '5px', padding: '8px', width: '250px' }}
              required
            />
          </div>
          <button
            type="submit"
            disabled={createUserLoading}
            style={{
              padding: '8px 16px',
              backgroundColor: '#28a745',
              color: 'white',
              border: 'none',
              borderRadius: '4px',
              cursor: createUserLoading ? 'not-allowed' : 'pointer',
            }}
          >
            {createUserLoading ? 'Creating...' : 'Create User'}
          </button>
        </form>

        {/* Users List */}
        {usersLoading ? (
          <p>Loading users...</p>
        ) : usersError ? (
          <p style={{ color: 'red' }}>Error: {usersError}</p>
        ) : users ? (
          <div>
            <h3>Users List ({users.length})</h3>
            {users.length === 0 ? (
              <p>No users found</p>
            ) : (
              <div style={{ display: 'grid', gap: '10px' }}>
                {users.map((user) => (
                  <div
                    key={user.id}
                    style={{
                      padding: '10px',
                      border: '1px solid #eee',
                      borderRadius: '4px',
                      backgroundColor: '#f9f9f9',
                    }}
                  >
                    <strong>{user.name}</strong> - {user.email}
                    <br />
                    <small>ID: {user.id}</small>
                  </div>
                ))}
              </div>
            )}
          </div>
        ) : (
          <p>No user data available</p>
        )}
      </section>
    </div>
  );
};

export default ApiDemo;
