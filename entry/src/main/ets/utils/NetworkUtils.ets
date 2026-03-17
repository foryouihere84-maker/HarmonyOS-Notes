/**
 * 网络工具类
 * 提供HTTP客户端功能，支持请求重试和错误处理
 * 
 * @author 开发者
 * @date 2026-03-12
 */
import http from '@ohos.net.http';
import { Logger } from './Logger';

/**
 * HTTP请求方法
 */
export enum HttpMethod {
  GET = 'GET',
  POST = 'POST',
  PUT = 'PUT',
  DELETE = 'DELETE',
  PATCH = 'PATCH',
  HEAD = 'HEAD',
  OPTIONS = 'OPTIONS'
}

/**
 * HTTP响应
 */
export interface HttpResponse {
  statusCode: number;
  headers: Record<string, string>;
  data: string;
  statusMessage: string;
}

/**
 * HTTP请求配置
 */
export interface HttpRequestConfig {
  method: HttpMethod;
  url: string;
  headers?: Record<string, string>;
  data?: string | Object | ArrayBuffer;
  timeout?: number;
  expectDataType?: http.HttpDataType;
  readTimeout?: number;
  connectTimeout?: number;
}

/**
 * 重试配置
 */
export interface RetryConfig {
  maxRetries: number;
  retryDelay: number;
  retryableStatusCodes: number[];
}

export class NetworkUtils {
  private static readonly TAG: string = 'NetworkUtils';
  private static readonly DEFAULT_TIMEOUT: number = 30000; // 30秒
  private static readonly DEFAULT_RETRY_CONFIG: RetryConfig = {
    maxRetries: 3,
    retryDelay: 1000,
    retryableStatusCodes: [408, 429, 500, 502, 503, 504]
  };
  
  /**
   * 发送HTTP请求
   * @param config 请求配置
   * @param retryConfig 重试配置
   * @returns HTTP响应
   */
  public static async request(
    config: HttpRequestConfig,
    retryConfig: RetryConfig = NetworkUtils.DEFAULT_RETRY_CONFIG
  ): Promise<HttpResponse> {
    let lastError: Error | null = null;
    
    for (let attempt = 0; attempt <= retryConfig.maxRetries; attempt++) {
      try {
        const response = await NetworkUtils.executeRequest(config);
        Logger.i(NetworkUtils.TAG, `请求成功: ${config.method} ${config.url} - ${response.statusCode}`);
        return response;
      } catch (error) {
        lastError = error as Error;
        Logger.w(NetworkUtils.TAG, `请求失败 (尝试 ${attempt + 1}/${retryConfig.maxRetries + 1}): ${error}`);
        
        // 如果是最后一次尝试，不再重试
        if (attempt === retryConfig.maxRetries) {
          break;
        }
        
        // 检查是否应该重试
        if (!NetworkUtils.shouldRetry(error, retryConfig.retryableStatusCodes)) {
          break;
        }
        
        // 等待重试延迟
        await NetworkUtils.sleep(retryConfig.retryDelay * (attempt + 1));
      }
    }
    
    throw lastError || new Error('请求失败');
  }
  
  /**
   * 执行HTTP请求
   * @param config 请求配置
   * @returns HTTP响应
   */
  private static async executeRequest(config: HttpRequestConfig): Promise<HttpResponse> {
    const httpRequest = http.createHttp();
    
    try {
      const headers: Record<string, string> = config.headers || {};
      
      // 将HttpMethod转换为http.RequestMethod
      let requestMethod: http.RequestMethod;
      switch (config.method) {
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
      
      const httpOptions: http.HttpRequestOptions = {
        method: requestMethod,
        header: headers,
        readTimeout: config.readTimeout || config.timeout || NetworkUtils.DEFAULT_TIMEOUT,
        connectTimeout: config.connectTimeout || config.timeout || NetworkUtils.DEFAULT_TIMEOUT,
        expectDataType: config.expectDataType || http.HttpDataType.STRING
      };
      
      // 设置请求体
      if (config.data !== undefined) {
        if (typeof config.data === 'string') {
          httpOptions.extraData = config.data;
          // 确保Content-Type header被设置
          const requestHeaders: Record<string, string> = headers || {};
          if (!requestHeaders['Content-Type']) {
            requestHeaders['Content-Type'] = 'application/x-www-form-urlencoded';
          }
          httpOptions.header = requestHeaders;
        } else if (config.data instanceof ArrayBuffer) {
          httpOptions.extraData = config.data;
        } else {
          httpOptions.extraData = JSON.stringify(config.data);
          const requestHeaders: Record<string, string> = headers || {};
          if (!requestHeaders['Content-Type']) {
            requestHeaders['Content-Type'] = 'application/json';
          }
          httpOptions.header = requestHeaders;
        }
      }
      
      Logger.d(NetworkUtils.TAG, `发送请求: ${config.method} ${config.url}`);
      Logger.d(NetworkUtils.TAG, `请求方法: ${requestMethod}`);
      Logger.d(NetworkUtils.TAG, `请求头: ${JSON.stringify(httpOptions.header)}`);
      Logger.d(NetworkUtils.TAG, `请求体: ${httpOptions.extraData ? httpOptions.extraData.toString().substring(0, 200) : '无'}`);
      
      const response = await httpRequest.request(config.url, httpOptions);
      
      const httpResponse: HttpResponse = {
        statusCode: response.responseCode,
        headers: response.header as Record<string, string>,
        data: response.result as string,
        statusMessage: ''
      };
      
      // 检查HTTP状态码
      if (httpResponse.statusCode < 200 || httpResponse.statusCode >= 300) {
        const errorData = httpResponse.data || httpResponse.statusMessage || 'Unknown error';
        throw new Error(`HTTP ${httpResponse.statusCode}: ${errorData}`);
      }
      
      return httpResponse;
    } finally {
      httpRequest.destroy();
    }
  }
  
  /**
   * 判断是否应该重试
   * @param error 错误对象
   * @param retryableStatusCodes 可重试的状态码
   * @returns 是否应该重试
   */
  private static shouldRetry(error: Error, retryableStatusCodes: number[]): boolean {
    const errorMessage = error.message;
    
    // 检查是否是网络错误
    if (errorMessage.includes('network') || 
        errorMessage.includes('timeout') || 
        errorMessage.includes('connection')) {
      return true;
    }
    
    // 检查是否是可重试的HTTP状态码
    for (const statusCode of retryableStatusCodes) {
      if (errorMessage.includes(statusCode.toString())) {
        return true;
      }
    }
    
    return false;
  }
  
  /**
   * 睡眠指定时间
   * @param ms 毫秒数
   * @returns Promise
   */
  private static sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
  
  /**
   * GET请求
   * @param url URL
   * @param headers 请求头
   * @param retryConfig 重试配置
   * @returns HTTP响应
   */
  public static async get(
    url: string,
    headers?: Record<string, string>,
    retryConfig?: RetryConfig
  ): Promise<HttpResponse> {
    return NetworkUtils.request({
      method: HttpMethod.GET,
      url,
      headers
    }, retryConfig);
  }
  
  /**
   * POST请求
   * @param url URL
   * @param data 请求数据
   * @param headers 请求头
   * @param retryConfig 重试配置
   * @returns HTTP响应
   */
  public static async post(
    url: string,
    data?: string | Object | ArrayBuffer,
    headers?: Record<string, string>,
    retryConfig?: RetryConfig
  ): Promise<HttpResponse> {
    return NetworkUtils.request({
      method: HttpMethod.POST,
      url,
      data,
      headers
    }, retryConfig);
  }
  
  /**
   * PUT请求
   * @param url URL
   * @param data 请求数据
   * @param headers 请求头
   * @param retryConfig 重试配置
   * @returns HTTP响应
   */
  public static async put(
    url: string,
    data?: string | Object | ArrayBuffer,
    headers?: Record<string, string>,
    retryConfig?: RetryConfig
  ): Promise<HttpResponse> {
    return NetworkUtils.request({
      method: HttpMethod.PUT,
      url,
      data,
      headers
    }, retryConfig);
  }
  
  /**
   * DELETE请求
   * @param url URL
   * @param headers 请求头
   * @param retryConfig 重试配置
   * @returns HTTP响应
   */
  public static async delete(
    url: string,
    headers?: Record<string, string>,
    retryConfig?: RetryConfig
  ): Promise<HttpResponse> {
    return NetworkUtils.request({
      method: HttpMethod.DELETE,
      url,
      headers
    }, retryConfig);
  }
  
  /**
   * PATCH请求
   * @param url URL
   * @param data 请求数据
   * @param headers 请求头
   * @param retryConfig 重试配置
   * @returns HTTP响应
   */
  public static async patch(
    url: string,
    data?: string | Object | ArrayBuffer,
    headers?: Record<string, string>,
    retryConfig?: RetryConfig
  ): Promise<HttpResponse> {
    return NetworkUtils.request({
      method: HttpMethod.PATCH,
      url,
      data,
      headers
    }, retryConfig);
  }
  
  /**
   * 上传文件
   * @param url URL
   * @param filePath 文件路径
   * @param headers 请求头
   * @param retryConfig 重试配置
   * @returns HTTP响应
   */
  public static async uploadFile(
    url: string,
    filePath: string,
    headers?: Record<string, string>,
    retryConfig?: RetryConfig
  ): Promise<HttpResponse> {
    // TODO: 实现文件上传功能
    throw new Error('文件上传功能待实现');
  }
  
  /**
   * 下载文件
   * @param url URL
   * @param savePath 保存路径
   * @param headers 请求头
   * @param retryConfig 重试配置
   * @returns HTTP响应
   */
  public static async downloadFile(
    url: string,
    savePath: string,
    headers?: Record<string, string>,
    retryConfig?: RetryConfig
  ): Promise<HttpResponse> {
    // TODO: 实现文件下载功能
    throw new Error('文件下载功能待实现');
  }
  
  /**
   * 构建URL查询字符串
   * @param baseUrl 基础URL
   * @param params 查询参数
   * @returns 完整URL
   */
  public static buildUrl(baseUrl: string, params?: Record<string, string | number>): string {
    if (!params || Object.keys(params).length === 0) {
      return baseUrl;
    }
    
    const queryString = Object.keys(params)
      .map(key => `${encodeURIComponent(key)}=${encodeURIComponent(params[key].toString())}`)
      .join('&');
    
    const separator = baseUrl.includes('?') ? '&' : '?';
    return `${baseUrl}${separator}${queryString}`;
  }
  
  /**
   * 解析JSON响应
   * @param response HTTP响应
   * @returns 解析后的JSON对象
   */
  public static parseJSON<T>(response: HttpResponse): T {
    try {
      return JSON.parse(response.data) as T;
    } catch (error) {
      Logger.e(NetworkUtils.TAG, `解析JSON失败: ${error}`);
      throw new Error('解析JSON失败');
    }
  }
  
  /**
   * 检查网络连接状态
   * @returns 是否连接到网络
   */
  public static async isNetworkAvailable(): Promise<boolean> {
    // TODO: 实现网络连接状态检查
    return true;
  }
}
