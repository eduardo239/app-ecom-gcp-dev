// Base API Response structure
export interface ApiResponse<T = unknown> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
  count?: number;
}

// Product related types
export interface Product {
  id: string;
  name: string;
  price: number;
  category: string;
}

export interface CreateProductRequest {
  name: string;
  price: number;
  category: string;
}

export interface UpdateProductRequest {
  name?: string;
  price?: number;
  category?: string;
}

// User related types
export interface User {
  id: string;
  name: string;
  email: string;
}

export interface CreateUserRequest {
  name: string;
  email: string;
}

// API Error type
export interface ApiError {
  success: false;
  error: string;
}

// Health check response
export interface HealthResponse {
  status: string;
  timestamp: string;
}

// Welcome message response
export interface WelcomeResponse {
  message: string;
  version: string;
  timestamp: string;
}
