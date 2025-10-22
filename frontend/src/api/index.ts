// Export all API types
export type * from './types';

// Export API clients
export { apiClient, ApiClient } from './client';
export { productApi, ProductApi } from './products';
export { userApi, UserApi } from './users';

// Export custom hooks
export {
  useProducts,
  useProduct,
  useUsers,
  useCreateProduct,
  useUpdateProduct,
  useDeleteProduct,
  useCreateUser,
  useApiHealth,
  useApiWelcome,
} from './hooks';
