import { useState, useEffect, useCallback } from 'react';
import { productApi } from './products';
import { userApi } from './users';
import { apiClient } from './client';
import type {
  Product,
  User,
  CreateProductRequest,
  UpdateProductRequest,
  CreateUserRequest,
  WelcomeResponse,
  HealthResponse,
} from './types';

// Generic hook for API state management
interface ApiState<T> {
  data: T | null;
  loading: boolean;
  error: string | null;
}

// Product hooks
export function useProducts() {
  const [state, setState] = useState<ApiState<Product[]>>({
    data: null,
    loading: true,
    error: null,
  });

  const fetchProducts = useCallback(async () => {
    setState((prev) => ({ ...prev, loading: true, error: null }));

    try {
      const response = await productApi.getAllProducts();
      if (response.success && response.data) {
        setState({ data: response.data, loading: false, error: null });
      } else {
        setState({
          data: null,
          loading: false,
          error: response.error || 'Failed to fetch products',
        });
      }
    } catch (error) {
      setState({
        data: null,
        loading: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      });
    }
  }, []);

  useEffect(() => {
    fetchProducts();
  }, [fetchProducts]);

  return { ...state, refetch: fetchProducts };
}

export function useProduct(id: string | null) {
  const [state, setState] = useState<ApiState<Product>>({
    data: null,
    loading: false,
    error: null,
  });

  const fetchProduct = useCallback(async (productId: string) => {
    setState((prev) => ({ ...prev, loading: true, error: null }));

    try {
      const response = await productApi.getProductById(productId);
      if (response.success && response.data) {
        setState({ data: response.data, loading: false, error: null });
      } else {
        setState({
          data: null,
          loading: false,
          error: response.error || 'Failed to fetch product',
        });
      }
    } catch (error) {
      setState({
        data: null,
        loading: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      });
    }
  }, []);

  useEffect(() => {
    if (id) {
      fetchProduct(id);
    }
  }, [id, fetchProduct]);

  return { ...state, refetch: id ? () => fetchProduct(id) : () => {} };
}

// User hooks
export function useUsers() {
  const [state, setState] = useState<ApiState<User[]>>({
    data: null,
    loading: true,
    error: null,
  });

  const fetchUsers = useCallback(async () => {
    setState((prev) => ({ ...prev, loading: true, error: null }));

    try {
      const response = await userApi.getAllUsers();
      if (response.success && response.data) {
        setState({ data: response.data, loading: false, error: null });
      } else {
        setState({
          data: null,
          loading: false,
          error: response.error || 'Failed to fetch users',
        });
      }
    } catch (error) {
      setState({
        data: null,
        loading: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      });
    }
  }, []);

  useEffect(() => {
    fetchUsers();
  }, [fetchUsers]);

  return { ...state, refetch: fetchUsers };
}

// Mutation hooks for create, update, delete operations
export function useCreateProduct() {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const createProduct = useCallback(
    async (productData: CreateProductRequest): Promise<Product | null> => {
      setLoading(true);
      setError(null);

      try {
        const response = await productApi.createProduct(productData);
        if (response.success && response.data) {
          setLoading(false);
          return response.data;
        } else {
          setError(response.error || 'Failed to create product');
          setLoading(false);
          return null;
        }
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : 'Unknown error';
        setError(errorMessage);
        setLoading(false);
        return null;
      }
    },
    []
  );

  return { createProduct, loading, error };
}

export function useUpdateProduct() {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const updateProduct = useCallback(
    async (
      id: string,
      updates: UpdateProductRequest
    ): Promise<Product | null> => {
      setLoading(true);
      setError(null);

      try {
        const response = await productApi.updateProduct(id, updates);
        if (response.success && response.data) {
          setLoading(false);
          return response.data;
        } else {
          setError(response.error || 'Failed to update product');
          setLoading(false);
          return null;
        }
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : 'Unknown error';
        setError(errorMessage);
        setLoading(false);
        return null;
      }
    },
    []
  );

  return { updateProduct, loading, error };
}

export function useDeleteProduct() {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const deleteProduct = useCallback(async (id: string): Promise<boolean> => {
    setLoading(true);
    setError(null);

    try {
      const response = await productApi.deleteProduct(id);
      if (response.success) {
        setLoading(false);
        return true;
      } else {
        setError(response.error || 'Failed to delete product');
        setLoading(false);
        return false;
      }
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : 'Unknown error';
      setError(errorMessage);
      setLoading(false);
      return false;
    }
  }, []);

  return { deleteProduct, loading, error };
}

export function useCreateUser() {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const createUser = useCallback(
    async (userData: CreateUserRequest): Promise<User | null> => {
      setLoading(true);
      setError(null);

      try {
        const response = await userApi.createUser(userData);
        if (response.success && response.data) {
          setLoading(false);
          return response.data;
        } else {
          setError(response.error || 'Failed to create user');
          setLoading(false);
          return null;
        }
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : 'Unknown error';
        setError(errorMessage);
        setLoading(false);
        return null;
      }
    },
    []
  );

  return { createUser, loading, error };
}

// General API hooks
export function useApiHealth() {
  const [state, setState] = useState<ApiState<HealthResponse>>({
    data: null,
    loading: true,
    error: null,
  });

  const checkHealth = useCallback(async () => {
    setState((prev) => ({ ...prev, loading: true, error: null }));

    try {
      const response = await apiClient.get<HealthResponse>('/health');
      if (response.success && response.data) {
        setState({ data: response.data, loading: false, error: null });
      } else {
        setState({
          data: null,
          loading: false,
          error: response.error || 'Failed to check API health',
        });
      }
    } catch (error) {
      setState({
        data: null,
        loading: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      });
    }
  }, []);

  useEffect(() => {
    checkHealth();
  }, [checkHealth]);

  return { ...state, checkHealth };
}

export function useApiWelcome() {
  const [state, setState] = useState<ApiState<WelcomeResponse>>({
    data: null,
    loading: true,
    error: null,
  });

  const getWelcome = useCallback(async () => {
    setState((prev) => ({ ...prev, loading: true, error: null }));

    try {
      const response = await apiClient.get<WelcomeResponse>('/');
      if (response.success && response.data) {
        setState({ data: response.data, loading: false, error: null });
      } else {
        setState({
          data: null,
          loading: false,
          error: response.error || 'Failed to get welcome message',
        });
      }
    } catch (error) {
      setState({
        data: null,
        loading: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      });
    }
  }, []);

  useEffect(() => {
    getWelcome();
  }, [getWelcome]);

  return { ...state, getWelcome };
}
