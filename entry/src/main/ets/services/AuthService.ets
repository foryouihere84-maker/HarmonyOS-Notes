import { http } from '@kit.NetworkKit';
import { User } from '../models/User';
import { Logger } from '../utils/Logger';
import { HttpMethod } from '../utils/NetworkUtils';
import { AppConstants } from '../constants/AppConstants';

export interface LoginRequest {
  username: string;
  password: string;
}

export interface RegisterRequest {
  username: string;
  email: string;
  password: string;
  confirmPassword: string;
}

export interface LoginResponse {
  success: boolean;
  message: string;
  data?: AuthData;
}

export interface RegisterResponse {
  success: boolean;
  message: string;
  data?: AuthData;
}

export interface AuthData {
  user: User;
  token: string;
}

export class AuthService {
  private static instance: AuthService;
  private static readonly BASE_URL: string = AppConstants.AUTH_BASE_URL;
  private static readonly LOGIN_ENDPOINT: string = '/api/auth/login';
  private static readonly REGISTER_ENDPOINT: string = '/api/auth/regist';
  private static readonly TIMEOUT: number = 10000;
  
  private constructor() {}
  
  public static getInstance(): AuthService {
    if (!AuthService.instance) {
      AuthService.instance = new AuthService();
    }
    return AuthService.instance;
  }
  
  public async login(username: string, password: string): Promise<LoginResponse> {
    try {
      const request: LoginRequest = {
        username: username,
        password: password
      };
      
      const response = await this.sendRequest<LoginResponse>(
        AuthService.LOGIN_ENDPOINT,
        HttpMethod.POST,
        request
      );
      
      if (response.success && response.data) {
        Logger.i('AuthService', `登录成功: ${username}`);
      } else {
        Logger.w('AuthService', `登录失败: ${response.message}`);
      }
      
      return response;
    } catch (error) {
      Logger.e('AuthService', `登录请求失败: ${error}`);
      return {
        success: false,
        message: `网络请求失败: ${error}`
      };
    }
  }
  
  public async register(username: string, email: string, password: string, confirmPassword: string): Promise<RegisterResponse> {
    try {
      if (password !== confirmPassword) {
        return {
          success: false,
          message: '两次输入的密码不一致'
        };
      }
      
      const request: RegisterRequest = {
        username: username,
        email: email,
        password: password,
        confirmPassword: confirmPassword
      };
      
      const response = await this.sendRequest<RegisterResponse>(
        AuthService.REGISTER_ENDPOINT,
        HttpMethod.POST,
        request
      );
      
      if (response.success && response.data) {
        Logger.i('AuthService', `注册成功: ${username}`);
      } else {
        Logger.w('AuthService', `注册失败: ${response.message}`);
      }
      
      return response;
    } catch (error) {
      Logger.e('AuthService', `注册请求失败: ${error}`);
      return {
        success: false,
        message: `网络请求失败: ${error}`
      };
    }
  }
  
  private async sendRequest<T>(endpoint: string, method: HttpMethod, data?: Object): Promise<T> {
    const url = `${AuthService.BASE_URL}${endpoint}`;
    
    const httpRequest = http.createHttp();
    
    try {
      // 将 HttpMethod 转换为 http.RequestMethod
      let requestMethod: http.RequestMethod;
      switch (method) {
        case HttpMethod.GET:
          requestMethod = http.RequestMethod.GET;
          break;
        case HttpMethod.POST:
          requestMethod = http.RequestMethod.POST;
          break;
        case HttpMethod.PUT:
          requestMethod = http.RequestMethod.PUT;
          break;
        case HttpMethod.DELETE:
          requestMethod = http.RequestMethod.DELETE;
          break;
        case HttpMethod.PATCH:
          // PATCH 方法可能不被支持，使用 POST 代替
          requestMethod = http.RequestMethod.POST;
          break;
        case HttpMethod.HEAD:
          requestMethod = http.RequestMethod.HEAD;
          break;
        case HttpMethod.OPTIONS:
          requestMethod = http.RequestMethod.OPTIONS;
          break;
        default:
          requestMethod = http.RequestMethod.GET;
          break;
      }
      
      const options: http.HttpRequestOptions = {
        method: requestMethod,
        header: {
          'Content-Type': 'application/json'
        },
        connectTimeout: AuthService.TIMEOUT,
        readTimeout: AuthService.TIMEOUT,
        extraData: data ? JSON.stringify(data) : undefined
      };
      
      const response = await httpRequest.request(url, options);
      
      if (response.responseCode === 200) {
        const result = JSON.parse(response.result as string) as T;
        return result;
      } else {
        throw new Error(`HTTP ${response.responseCode}: ${response.result}`);
      }
    } finally {
      httpRequest.destroy();
    }
  }
}
