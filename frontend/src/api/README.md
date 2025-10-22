# Frontend API Layer

This directory contains the complete API layer for connecting the React frontend with the Python Flask backend.

## Structure

```
src/api/
├── index.ts          # Main exports
├── types.ts          # TypeScript type definitions
├── client.ts         # Base API client using fetch
├── products.ts       # Product-related API functions
├── users.ts          # User-related API functions
└── hooks.ts          # Custom React hooks for API operations
```

## Features

- **Type-safe API calls** with TypeScript
- **Custom React hooks** for easy data fetching and state management
- **Error handling** with consistent error responses
- **Loading states** for better UX
- **CRUD operations** for products and users
- **Automatic refetching** capabilities

## Usage

### Basic API Calls

```tsx
import { productApi, userApi } from '../api';

// Get all products
const response = await productApi.getAllProducts();
if (response.success) {
  console.log(response.data); // Product[]
}

// Create a new user
const newUser = await userApi.createUser({
  name: 'John Doe',
  email: 'john@example.com',
});
```

### Using React Hooks

```tsx
import { useProducts, useCreateProduct } from '../api';

function ProductComponent() {
  // Fetch products with loading and error states
  const { data: products, loading, error, refetch } = useProducts();

  // Create product mutation
  const { createProduct, loading: creating } = useCreateProduct();

  const handleCreate = async () => {
    const result = await createProduct({
      name: 'New Product',
      price: 29.99,
      category: 'Electronics',
    });

    if (result) {
      refetch(); // Refresh the products list
    }
  };

  if (loading) return <div>Loading...</div>;
  if (error) return <div>Error: {error}</div>;

  return (
    <div>
      {products?.map((product) => (
        <div key={product.id}>{product.name}</div>
      ))}
      <button onClick={handleCreate} disabled={creating}>
        Create Product
      </button>
    </div>
  );
}
```

## Available Hooks

### Data Fetching Hooks

- `useProducts()` - Fetch all products
- `useProduct(id)` - Fetch single product by ID
- `useUsers()` - Fetch all users
- `useApiHealth()` - Check API health status
- `useApiWelcome()` - Get API welcome message

### Mutation Hooks

- `useCreateProduct()` - Create new product
- `useUpdateProduct()` - Update existing product
- `useDeleteProduct()` - Delete product
- `useCreateUser()` - Create new user

## Configuration

The API client is configured to connect to `http://localhost:5000` by default. To change this, modify the `BASE_URL` constant in `client.ts`.

## Error Handling

All API functions return a consistent response format:

```typescript
interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
  count?: number;
}
```

Errors are automatically handled and propagated through the hooks' error states.

## Backend Requirements

This frontend API layer expects the Python Flask backend to be running on `http://localhost:5000` with the following endpoints:

- `GET /` - Welcome message
- `GET /health` - Health check
- `GET /api/products` - Get all products
- `POST /api/products` - Create product
- `PUT /api/products/:id` - Update product
- `DELETE /api/products/:id` - Delete product
- `GET /api/users` - Get all users
- `POST /api/users` - Create user

Make sure CORS is enabled on the backend to allow cross-origin requests from the frontend.
