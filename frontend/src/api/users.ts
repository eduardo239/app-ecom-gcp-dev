import { apiClient } from './client';
import type { User, CreateUserRequest, ApiResponse } from './types';

export class UserApi {
  /**
   * Get all users
   */
  async getAllUsers(): Promise<ApiResponse<User[]>> {
    return apiClient.get<User[]>('/api/users');
  }

  /**
   * Get a specific user by ID
   */
  async getUserById(id: string): Promise<ApiResponse<User>> {
    return apiClient.get<User>(`/api/users/${id}`);
  }

  /**
   * Create a new user
   */
  async createUser(user: CreateUserRequest): Promise<ApiResponse<User>> {
    return apiClient.post<User>('/api/users', user);
  }
}

// Create and export a default instance
export const userApi = new UserApi();
