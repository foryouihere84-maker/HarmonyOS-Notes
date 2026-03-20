import { http } from '@kit.NetworkKit';
import { Logger } from './Logger';
import { AppConstants } from '../constants/AppConstants';

export class NetworkTest {
  private static readonly TAG: string = 'NetworkTest';

  public static async testConnection(): Promise<boolean> {
    Logger.i(NetworkTest.TAG, '========== 开始网络连接测试 ==========');
    
    const testUrls = [
      AppConstants.AUTH_BASE_URL,
      AppConstants.API_BASE_URL
    ];
    
    for (const baseUrl of testUrls) {
      const success = await NetworkTest.testUrl(baseUrl);
      if (!success) {
        Logger.e(NetworkTest.TAG, `测试失败: ${baseUrl}`);
        return false;
      }
    }
    
    Logger.i(NetworkTest.TAG, '========== 所有网络连接测试通过 ==========');
    return true;
  }

  private static async testUrl(baseUrl: string): Promise<boolean> {
    Logger.i(NetworkTest.TAG, `测试 URL: ${baseUrl}`);
    
    const httpRequest = http.createHttp();
    
    try {
      const testUrl = `${baseUrl}/api/v16/ai/history`;
      Logger.i(NetworkTest.TAG, `发送测试请求到: ${testUrl}`);
      
      const response = await httpRequest.request(testUrl, {
        method: http.RequestMethod.GET,
        header: {
          'Content-Type': 'application/json'
        },
        connectTimeout: 5000,
        readTimeout: 5000
      });
      
      Logger.i(NetworkTest.TAG, `响应状态码: ${response.responseCode}`);
      Logger.i(NetworkTest.TAG, `响应内容: ${response.result}`);
      
      if (response.responseCode >= 200 && response.responseCode < 300) {
        Logger.i(NetworkTest.TAG, `✓ ${baseUrl} 连接成功`);
        return true;
      } else {
        Logger.e(NetworkTest.TAG, `✗ ${baseUrl} 连接失败，状态码: ${response.responseCode}`);
        return false;
      }
    } catch (error) {
      Logger.e(NetworkTest.TAG, `✗ ${baseUrl} 连接异常: ${error}`);
      return false;
    } finally {
      httpRequest.destroy();
    }
  }

  public static async testAIEndpoint(): Promise<boolean> {
    Logger.i(NetworkTest.TAG, '========== 测试AI端点 ==========');
    
    const url = `${AppConstants.API_BASE_URL}/api/v16/ai/func`;
    const httpRequest = http.createHttp();
    
    try {
      Logger.i(NetworkTest.TAG, `测试 URL: ${url}`);
      
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json',
          'Accept': 'text/event-stream'
        },
        extraData: JSON.stringify({
          message: '请提炼以下内容：测试',
          processType: 'extract',
          userId: 'test',
          saveHistory: false
        }),
        connectTimeout: 10000,
        readTimeout: 10000
      });
      
      Logger.i(NetworkTest.TAG, `响应状态码: ${response.responseCode}`);
      Logger.i(NetworkTest.TAG, `响应内容: ${response.result}`);
      
      if (response.responseCode >= 200 && response.responseCode < 300) {
        Logger.i(NetworkTest.TAG, `✓ AI端点测试成功`);
        return true;
      } else {
        Logger.e(NetworkTest.TAG, `✗ AI端点测试失败，状态码: ${response.responseCode}`);
        return false;
      }
    } catch (error) {
      Logger.e(NetworkTest.TAG, `✗ AI端点测试异常: ${error}`);
      return false;
    } finally {
      httpRequest.destroy();
    }
  }
}
