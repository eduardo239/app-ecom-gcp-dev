import { apiClient } from './client';
import type {
  Product,
  CreateProductRequest,
  UpdateProductRequest,
  ApiResponse,
} from './types';

export class ProductApi {
  /**
   * Get all products
   */
  async getAllProducts(): Promise<ApiResponse<Product[]>> {
    return apiClient.get<Product[]>('/api/products');
  }

  /**
   * Get a specific product by ID
   */
  async getProductById(id: string): Promise<ApiResponse<Product>> {
    return apiClient.get<Product>(`/api/products/${id}`);
  }

  /**
   * Create a new product
   */
  async createProduct(
    product: CreateProductRequest
  ): Promise<ApiResponse<Product>> {
    return apiClient.post<Product>('/api/products', product);
  }

  /**
   * Update an existing product
   */
  async updateProduct(
    id: string,
    updates: UpdateProductRequest
  ): Promise<ApiResponse<Product>> {
    return apiClient.put<Product>(`/api/products/${id}`, updates);
  }

  /**
   * Delete a product
   */
  async deleteProduct(id: string): Promise<ApiResponse<void>> {
    return apiClient.delete<void>(`/api/products/${id}`);
  }
}

// Create and export a default instance
export const productApi = new ProductApi();
