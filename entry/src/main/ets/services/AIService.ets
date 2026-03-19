import { http } from '@kit.NetworkKit';
import { Logger } from '../utils/Logger';
import { BusinessError } from '@kit.BasicServicesKit';
import util from '@ohos.util';

export interface AIChatRequest {
  message: string;
  sessionId?: string;
  model?: string;
}

export interface AIStreamChunk {
  content: string;
  done: boolean;
  error?: string;
}

export class AIService {
  private static instance: AIService;
  private static readonly BASE_URL: string = 'http://192.168.3.17:8080';
  private static readonly CHAT_ENDPOINT: string = '/api/v16/ai/chat';
  private static readonly TIMEOUT: number = 60000;
  
  private constructor() {}
  
  public static getInstance(): AIService {
    if (!AIService.instance) {
      AIService.instance = new AIService();
    }
    return AIService.instance;
  }
  
  public chatStream(
    message: string,
    onChunk: (chunk: AIStreamChunk) => void,
    onComplete: () => void,
    onError: (error: string) => void,
    sessionId?: string,
    model?: string
  ): void {
    const url = `${AIService.BASE_URL}${AIService.CHAT_ENDPOINT}`;
    const httpRequest = http.createHttp();
    let buffer: string = '';
    
    const request: AIChatRequest = {
      message: message,
      sessionId: sessionId,
      model: model
    };
    
    httpRequest.on('dataReceive', (data: string | ArrayBuffer) => {
      const dataStr: string = typeof data === 'string' ? data : new util.TextDecoder('utf-8').decode(new Uint8Array(data));
      Logger.i('AIService', `收到数据，长度：${dataStr.length}`);
      Logger.i('AIService', `原始数据：${dataStr}`);
      
      buffer += dataStr;
      
      const lines = buffer.split('\n');
      buffer = lines.pop() || '';
      
      Logger.i('AIService', `分割成 ${lines.length} 行，buffer剩余：${buffer.length} 字符`);
      
      for (const line of lines) {
        if (line.trim().startsWith('data: ')) {
          const dataContent = line.trim().substring(6);
          
          Logger.i('AIService', `解析数据内容：${dataContent}`);
          
          if (dataContent === '[DONE]') {
            Logger.i('AIService', '收到 [DONE] 标记');
            onChunk({ content: '', done: true });
            onComplete();
            httpRequest.destroy();
            return;
          }
          
          try {
            const chunk = JSON.parse(dataContent) as AIStreamChunk;
            Logger.i('AIService', `解析成功 - content类型: ${typeof chunk.content}, content值: "${chunk.content}", done: ${chunk.done}`);
            Logger.i('AIService', `完整chunk对象: ${JSON.stringify(chunk)}`);
            onChunk(chunk);
            
            if (chunk.done || chunk.error) {
              if (chunk.error) {
                onError(chunk.error);
              } else {
                onComplete();
              }
              httpRequest.destroy();
              return;
            }
          } catch (e) {
            Logger.e('AIService', `解析流数据失败：${e}, 数据：${dataContent}`);
          }
        }
      }
    });
    
    httpRequest.on('dataEnd', () => {
      Logger.i('AIService', '流式数据接收完毕');
      if (buffer.trim().length > 0) {
        if (buffer.trim().startsWith('data: ')) {
          const dataContent = buffer.trim().substring(6);
          if (dataContent !== '[DONE]') {
            try {
              const chunk = JSON.parse(dataContent) as AIStreamChunk;
              onChunk(chunk);
            } catch (e) {
              Logger.e('AIService', `解析最后数据失败：${e}`);
            }
          }
        }
      }
      onComplete();
      httpRequest.destroy();
    });
        
    httpRequest.requestInStream(url, {
      method: http.RequestMethod.POST,
      header: {
        'Content-Type': 'application/json',
        'Accept': 'text/event-stream'
      },
      extraData: JSON.stringify(request),
      connectTimeout: AIService.TIMEOUT,
      readTimeout: AIService.TIMEOUT
    }, (err: BusinessError) => {
      if (err) {
        Logger.e('AIService', `请求失败：${JSON.stringify(err)}`);
        onError(`请求失败：${err.message}`);
        httpRequest.destroy();
      }
    });
  }
}
