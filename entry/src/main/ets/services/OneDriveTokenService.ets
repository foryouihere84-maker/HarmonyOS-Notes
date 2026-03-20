/**
 * OneDrive Token 服务
 * 用于管理后端的 OneDrive 令牌
 * 
 * @author 开发者
 * @date 2026-03-19
 */

import { http } from '@kit.NetworkKit';
import { Logger } from '../utils/Logger';
import { AppConstants } from '../constants/AppConstants';

/**
 * OneDrive Token 响应接口
 */
export interface OneDriveTokenResponse {
  access_token: string;
  refresh_token: string;
  expires_in: number;
  token_type: string;
  scope: string;
}

/**
 * 授权URL响应接口
 */
export interface AuthUrlResponse {
  authUrl: string;
  state: string;
}

/**
 * API 响应接口
 */
export interface ApiResponse<T> {
  code: number;
  message: string;
  data: T;
}

/**
 * OneDrive Token 服务类
 */
export class OneDriveTokenService {
  private static instance: OneDriveTokenService;
  private static readonly BASE_URL: string = AppConstants.API_BASE_URL;
  private static readonly TIMEOUT: number = 30000;
  
  private constructor() {}
  
  public static getInstance(): OneDriveTokenService {
    if (!OneDriveTokenService.instance) {
      OneDriveTokenService.instance = new OneDriveTokenService();
    }
    return OneDriveTokenService.instance;
  }
  
  /**
   * 生成授权URL
   * @param userId 用户ID
   * @returns 授权URL和state
   */
  public async generateAuthUrl(userId: string): Promise<AuthUrlResponse | null> {
    try {
      const url = `${OneDriveTokenService.BASE_URL}/api/v16/onedrive/auth/url?userId=${userId}`;
      Logger.i('OneDriveTokenService', `生成授权URL: ${url}`);
      
      const response = await this.httpRequest(url);
      const data = JSON.parse(response.result.toString()) as ApiResponse<AuthUrlResponse>;
      
      if (data.code === 200 && data.data) {
        Logger.i('OneDriveTokenService', '生成授权URL成功');
        return data.data;
      } else {
        Logger.e('OneDriveTokenService', `生成授权URL失败: ${data.message}`);
        return null;
      }
    } catch (error) {
      Logger.e('OneDriveTokenService', `生成授权URL异常: ${error}`);
      return null;
    }
  }
  
  /**
   * 使用授权码交换访问令牌
   * @param code 授权码
   * @param state 状态参数
   * @param userId 用户ID
   * @returns 令牌响应
   */
  public async exchangeCodeForToken(
    code: string,
    state: string,
    userId: string
  ): Promise<OneDriveTokenResponse | null> {
    try {
      const url = `${OneDriveTokenService.BASE_URL}/api/v16/onedrive/auth/token`;
      const body = `code=${encodeURIComponent(code)}&state=${encodeURIComponent(state)}&userId=${encodeURIComponent(userId)}`;
      
      Logger.i('OneDriveTokenService', `交换访问令牌: ${url}`);
      
      const httpRequest = http.createHttp();
      const response = await new Promise<http.HttpResponse>((resolve, reject) => {
        httpRequest.request(url, {
          method: http.RequestMethod.POST,
          header: {
            'Content-Type': 'application/x-www-form-urlencoded'
          },
          extraData: body,
          connectTimeout: OneDriveTokenService.TIMEOUT,
          readTimeout: OneDriveTokenService.TIMEOUT
        }, (err, data) => {
          if (err) {
            reject(err);
          } else {
            resolve(data as http.HttpResponse);
          }
        });
      });
      
      const responseData = JSON.parse(response.result.toString()) as ApiResponse<OneDriveTokenResponse>;
      
      if (responseData.code === 200 && responseData.data) {
        Logger.i('OneDriveTokenService', '交换访问令牌成功');
        return responseData.data;
      } else {
        Logger.e('OneDriveTokenService', `交换访问令牌失败: ${responseData.message}`);
        return null;
      }
    } catch (error) {
      Logger.e('OneDriveTokenService', `交换访问令牌异常: ${error}`);
      return null;
    }
  }
  
  /**
   * 刷新访问令牌
   * @param userId 用户ID
   * @returns 令牌响应
   */
  public async refreshToken(userId: string): Promise<OneDriveTokenResponse | null> {
    try {
      const url = `${OneDriveTokenService.BASE_URL}/api/v16/onedrive/auth/refresh?userId=${userId}`;
      Logger.i('OneDriveTokenService', `刷新访问令牌: ${url}`);
      
      const httpRequest = http.createHttp();
      const response = await new Promise<http.HttpResponse>((resolve, reject) => {
        httpRequest.request(url, {
          method: http.RequestMethod.POST,
          header: {
            'Content-Type': 'application/x-www-form-urlencoded'
          },
          connectTimeout: OneDriveTokenService.TIMEOUT,
          readTimeout: OneDriveTokenService.TIMEOUT
        }, (err, data) => {
          if (err) {
            reject(err);
          } else {
            resolve(data as http.HttpResponse);
          }
        });
      });
      
      const responseData = JSON.parse(response.result.toString()) as ApiResponse<OneDriveTokenResponse>;
      
      if (responseData.code === 200 && responseData.data) {
        Logger.i('OneDriveTokenService', '刷新访问令牌成功');
        return responseData.data;
      } else {
        Logger.e('OneDriveTokenService', `刷新访问令牌失败: ${responseData.message}`);
        return null;
      }
    } catch (error) {
      Logger.e('OneDriveTokenService', `刷新访问令牌异常: ${error}`);
      return null;
    }
  }
  
  /**
   * 删除用户的令牌
   * @param userId 用户ID
   * @returns 是否成功
   */
  public async deleteToken(userId: string): Promise<boolean> {
    try {
      const url = `${OneDriveTokenService.BASE_URL}/api/v16/onedrive/auth/token?userId=${userId}`;
      Logger.i('OneDriveTokenService', `删除令牌: ${url}`);
      
      const httpRequest = http.createHttp();
      const response = await new Promise<http.HttpResponse>((resolve, reject) => {
        httpRequest.request(url, {
          method: http.RequestMethod.DELETE,
          header: {
            'Content-Type': 'application/json'
          },
          connectTimeout: OneDriveTokenService.TIMEOUT,
          readTimeout: OneDriveTokenService.TIMEOUT
        }, (err, data) => {
          if (err) {
            reject(err);
          } else {
            resolve(data as http.HttpResponse);
          }
        });
      });
      
      const responseData = JSON.parse(response.result.toString()) as ApiResponse<null>;
      
      if (responseData.code === 200) {
        Logger.i('OneDriveTokenService', '删除令牌成功');
        return true;
      } else {
        Logger.e('OneDriveTokenService', `删除令牌失败: ${responseData.message}`);
        return false;
      }
    } catch (error) {
      Logger.e('OneDriveTokenService', `删除令牌异常: ${error}`);
      return false;
    }
  }
  
  /**
   * HTTP 请求封装
   * @param url 请求URL
   * @returns 响应结果
   */
  private async httpRequest(url: string): Promise<http.HttpResponse> {
    return new Promise((resolve, reject) => {
      const httpRequest = http.createHttp();
      httpRequest.request(url, {
        method: http.RequestMethod.GET,
        header: {
          'Content-Type': 'application/json'
        },
        connectTimeout: OneDriveTokenService.TIMEOUT,
        readTimeout: OneDriveTokenService.TIMEOUT
      }, (err, data) => {
        if (err) {
          reject(err);
        } else {
          resolve(data as http.HttpResponse);
        }
      });
    });
  }
}
