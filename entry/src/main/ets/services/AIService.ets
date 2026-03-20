import { http } from '@kit.NetworkKit';
import { Logger } from '../utils/Logger';
import { BusinessError } from '@kit.BasicServicesKit';
import util from '@ohos.util';
import { AppConstants } from '../constants/AppConstants';

export interface AIChatRequest {
  message: string;
  sessionId?: string;
  model?: string;
  processType?: 'extract' | 'polish' | 'summarize' | 'expand';
  userId?: string;
  relatedNotes?: string;
  saveHistory?: boolean;
}

export interface AIStreamChunk {
  content: string;
  done: boolean;
  error?: string;
}

export interface AIBatchProcessRequest {
  action: 'extract' | 'polish' | 'summarize' | 'expand';
  texts: string[];
  sessionId?: string;
  model?: string;
}

export interface AIBatchProcessResult {
  success: boolean;
  results?: string[];
  error?: string;
}

export interface AIPageData {
  id: string;
  title: string;
  content: string;
}

export interface AIRelatedNote {
  id: string;
  title: string;
}

export interface AIProcessResult {
  id: string;
  title: string;
  result: string;
}

export class AIService {
  private static instance: AIService;
  private static readonly BASE_URL: string = AppConstants.API_BASE_URL;
  private static readonly CHAT_ENDPOINT: string = '/api/v16/ai/chat';
  private static readonly FUNC_ENDPOINT: string = '/api/v16/ai/func';
  private static readonly TIMEOUT: number = 300000;
  private static readonly MAX_RETRY_COUNT: number = 3;
  private static readonly RETRY_DELAY: number = 2000;
  
  private constructor() {}
  
  public static getInstance(): AIService {
    if (!AIService.instance) {
      AIService.instance = new AIService();
    }
    return AIService.instance;
  }
  
  /**
   * 文本分块处理（智能分块，保持语义完整性）
   * 将长文本按段落或固定大小切分成多个块
   */
  private chunkText(text: string, chunkSize: number = AppConstants.AI_CHUNK_SIZE): string[] {
    const chunks: string[] = [];
    
    if (text.length <= chunkSize) {
      return [text];
    }
    
    const paragraphs = text.split(/\n+/);
    let currentChunk = '';
    
    for (const paragraph of paragraphs) {
      const trimmedParagraph = paragraph.trim();
      if (!trimmedParagraph) {
        continue;
      }
      
      if (currentChunk.length + trimmedParagraph.length + 2 <= chunkSize) {
        currentChunk += (currentChunk ? '\n\n' : '') + trimmedParagraph;
      } else {
        if (currentChunk) {
          chunks.push(currentChunk);
        }
        
        if (trimmedParagraph.length > chunkSize) {
          const sentences = trimmedParagraph.split(/([。！？.!?]+)/);
          let sentenceChunk = '';
          
          for (let i = 0; i < sentences.length; i++) {
            const sentence = sentences[i].trim();
            if (!sentence) continue;
            
            if (sentenceChunk.length + sentence.length <= chunkSize) {
              sentenceChunk += sentence;
            } else {
              if (sentenceChunk) {
                chunks.push(sentenceChunk);
              }
              sentenceChunk = sentence;
            }
          }
          
          if (sentenceChunk) {
            currentChunk = sentenceChunk;
          } else {
            currentChunk = '';
          }
        } else {
          currentChunk = trimmedParagraph;
        }
      }
    }
    
    if (currentChunk) {
      chunks.push(currentChunk);
    }
    
    if (chunks.length > AppConstants.AI_MAX_CHUNKS) {
      Logger.w('AIService', `文本被切分成${chunks.length}块，超过最大限制${AppConstants.AI_MAX_CHUNKS}`);
      return chunks.slice(0, AppConstants.AI_MAX_CHUNKS);
    }
    
    Logger.i('AIService', `文本切分完成，共 ${chunks.length} 块`);
    return chunks;
  }
  
  /**
   * 构建 AI 提示词
   */
  private buildPrompt(action: string, text: string): string {
    const prompts: Record<string, string> = {
      'extract': `你是一位经验丰富的内容分析师和信息架构师。你的专长是从复杂文本中精准提取核心价值。

【任务目标】
对以下内容进行深度提炼和结构化呈现，帮助读者快速把握要点。

【思考步骤】
1. 首先通读全文，理解整体主题和核心意图
2. 识别并列出3-5个最重要的核心观点或关键信息
3. 提取所有重要的数据、数字、日期和统计信息
4. 梳理内容中的逻辑关系（因果、对比、并列等）
5. 如果内容涉及问题或挑战，提炼可行的解决方案或建议
6. 使用清晰的层级结构组织内容

【输出要求】
- 使用规范的Markdown格式，包括适当的标题层级（##、###）、列表（-、1.）、粗体（**）、斜体（*）
- 核心要点使用简洁有力的表达
- 关键数据和信息使用粗体或列表突出显示
- 确保内容既全面又简洁，便于快速理解和记忆
- 总长度控制在原文的40%-60%

【待处理内容】
${text}

【输出示例】
## 核心要点
- 要点1：简洁描述
- 要点2：简洁描述

## 关键数据
- 数据1：**具体数值**
- 数据2：**具体数值**

## 逻辑关系
- 关系1：A导致B
- 关系2：C与D形成对比

## 行动建议
1. 建议1
2. 建议2`,
      
      'polish': `你是一位资深的文字编辑和语言专家，拥有10年以上的专业写作和编辑经验。你的专长是将文字打磨得精准、流畅、专业。

【任务目标】
对以下内容进行专业润色，提升其表达质量、专业度和可读性。

【思考步骤】
1. 分析原文的语言风格和目标读者群体
2. 识别冗余、重复、口语化或不正式的表达
3. 优化句子结构和段落组织，增强逻辑连贯性
4. 选择更精准、专业的词汇替换模糊或平淡的表达
5. 调整句子长度，使用多样化的句式结构
6. 确保严格保持原文的核心意思和关键信息不变
7. 统一整体语言风格，根据内容性质选择正式或半正式语调

【输出要求】
- 语句通顺自然，消除冗余和重复
- 使用精准、专业的词汇
- 逻辑清晰，段落结构合理
- 可读性强，句式多样化
- 严格保持原文核心意思和关键信息
- 使用规范的Markdown格式，包括适当的标题、列表、强调等
- 整体风格统一

【待润色内容】
${text}

【润色原则】
- 优先考虑表达清晰度和准确性
- 避免过度修饰，保持简洁有力
- 专业术语使用准确，必要时添加简要说明
- 长句适当拆分，短句合理合并`,
      
      'summarize': `你是一位专业的信息整合专家和知识管理者。你的专长是从大量信息中提炼精华，形成高质量的总结。

【任务目标】
对以下内容进行全面而精炼的总结，帮助读者快速掌握核心价值。

【思考步骤】
1. 通读全文，理解整体主题、背景和核心价值
2. 用1-2句话概述内容的主题和核心价值
3. 提取并列出3-5个最重要的观点或论点
4. 整合所有重要的数据、事实、案例和证据
5. 使用清晰的逻辑结构（如：背景-问题-分析-结论）组织总结
6. 将原文长度压缩至30%-50%，同时保留所有关键信息
7. 如果内容涉及方法或步骤，总结出清晰的操作要点

【输出要求】
- 开头用1-2句话进行整体概括
- 主要观点使用列表形式呈现
- 关键信息突出显示
- 使用清晰的逻辑结构组织内容
- 简洁精炼，去除冗余
- 使用规范的Markdown语法，便于阅读和引用
- 总长度控制在原文的30%-50%

【待总结内容】
${text}

【输出结构建议】
## 整体概述
（1-2句话概括）

## 主要观点
- 观点1
- 观点2
- 观点3

## 关键信息
- 信息1
- 信息2

## 结论
（如果适用）`,
      
      'expand': `你是一位博学的内容创作专家，拥有跨学科的知识背景。你的专长是对现有内容进行深度拓展和丰富，使其更加全面、深入、有价值。

【任务目标】
对以下内容进行深度拓展和丰富，使其成为一篇内容详实、观点全面、实用性强的文章。

【思考步骤】
1. 理解原文的核心主题和目标读者
2. 添加相关的背景信息、历史脉络或上下文说明
3. 对每个要点进行详细阐述，添加具体的例子、案例或场景
4. 从不同维度（如技术、商业、社会、人文、实践等）扩展内容
5. 引用相关的统计数据、研究结果或权威资料来支撑观点
6. 如果内容涉及方法或技巧，提供具体的实施步骤和注意事项
7. 提出相关的思考问题、发展趋势或未来展望
8. 使用清晰的标题层级和段落结构，使内容层次分明

【输出要求】
- 拓展后的内容应该是原文的2-3倍
- 保持高质量的原创性和实用性
- 使用规范的Markdown语法，包括表格、代码块、引用等丰富格式
- 内容层次分明，逻辑清晰
- 添加实际案例和具体例子
- 引用权威数据或研究结果
- 提供可操作的建议或步骤

【待拓展内容】
${text}

【拓展方向建议】
- 背景：添加历史、现状、趋势等背景信息
- 细节：对每个要点展开详细说明
- 案例：添加真实或假设的案例
- 数据：引用统计数据、研究结果
- 视角：从多个角度分析
- 实践：提供具体的操作指南
- 延伸：提出思考问题或未来展望`
    };
    
    const prompt = prompts[action] || '请处理以下内容：';
    return prompt;
  }
  
  /**
   * 批量处理选中的笔记（智能分块处理）
   * @param action AI 操作类型
   * @param pages 页面对象列表（包含 id, title, content）
   * @param onProgress 进度回调
   * @param onComplete 完成回调
   * @param onError 错误回调
   */
  public batchProcessPages(
    action: 'extract' | 'polish' | 'summarize' | 'expand',
    pages: AIPageData[],
    onProgress: (progress: number, currentTitle: string, result: string) => void,
    onComplete: (results: AIProcessResult[]) => void,
    onError: (error: string) => void
  ): void {
    if (pages.length === 0) {
      onError('没有选中的笔记');
      return;
    }
    
    const allResults: AIProcessResult[] = [];
    let hasError = false;
    
    Logger.i('AIService', `开始批量处理 ${pages.length} 个笔记，操作类型：${action}`);
    onProgress(0, '准备中...', '');
    
    const processAllPages = () => {
      if (hasError) {
        return;
      }
      
      const actionNames: Record<string, string> = {
        'extract': '提炼',
        'polish': '润色',
        'summarize': '总结',
        'expand': '拓展'
      };
      
      const actionName = actionNames[action] || '处理';
      
      let combinedText = `请对以下 ${pages.length} 篇笔记进行${actionName}操作：\n\n`;
      
      for (let i = 0; i < pages.length; i++) {
        const page = pages[i];
        combinedText += `--- 笔记 ${i + 1} ---\n`;
        combinedText += `标题：${page.title}\n`;
        combinedText += `内容：${page.content || ''}\n\n`;
      }
      
      Logger.i('AIService', `合并后的文本长度：${combinedText.length}`);
      
      if (combinedText.length <= AppConstants.AI_MAX_TEXT_LENGTH) {
        Logger.i('AIService', '文本长度在阈值内，直接处理');
        onProgress(20, '发送请求...', '');
        
        this.processCombinedText(action, combinedText, pages, (results) => {
          allResults.push(...results);
          onProgress(100, '处理完成', '');
          onComplete(allResults);
        }, (error) => {
          hasError = true;
          onError(`批量处理失败：${error}`);
        });
      } else {
        Logger.i('AIService', '文本过长，启用分块处理');
        this.processWithChunks(action, combinedText, pages, onProgress, (results) => {
          allResults.push(...results);
          onProgress(100, '处理完成', '');
          onComplete(allResults);
        }, (error) => {
          hasError = true;
          onError(`批量处理失败：${error}`);
        });
      }
    };
    
    processAllPages();
  }
  
  /**
   * 分块处理长文本
   */
  private processWithChunks(
    action: string,
    combinedText: string,
    pages: AIPageData[],
    onProgress: (progress: number, currentTitle: string, result: string) => void,
    onSuccess: (results: AIProcessResult[]) => void,
    onError: (error: string) => void
  ): void {
    const chunks = this.chunkText(combinedText, AppConstants.AI_CHUNK_SIZE);
    Logger.i('AIService', `文本切分成 ${chunks.length} 块`);
    
    if (chunks.length > AppConstants.AI_MAX_CHUNKS) {
      onError(`文本过长，切分成 ${chunks.length} 块，超过最大限制 ${AppConstants.AI_MAX_CHUNKS}`);
      return;
    }
    
    const chunkResults: string[] = [];
    let chunkIndex = 0;
    let hasError = false;
    
    const processNextChunk = () => {
      if (hasError) {
        return;
      }
      
      if (chunkIndex >= chunks.length) {
        const mergedResult = chunkResults.join('\n\n---\n\n');
        Logger.i('AIService', '所有分块处理完成，合并结果');
        
        const actionNames: Record<string, string> = {
          'extract': '提炼',
          'polish': '润色',
          'summarize': '总结',
          'expand': '拓展'
        };
        
        const actionName = actionNames[action] || '处理';
        
        const results: AIProcessResult[] = pages.map((page, index): AIProcessResult => ({
          id: page.id,
          title: page.title,
          result: `【${page.title} - ${actionName}结果】\n\n${mergedResult}`
        }));
        
        onSuccess(results);
        return;
      }
      
      const progress = Math.round(((chunkIndex + 1) / chunks.length) * 80) + 10;
      onProgress(progress, `处理第 ${chunkIndex + 1}/${chunks.length} 块`, '');
      
      const chunkWithHeader = `这是第 ${chunkIndex + 1}/${chunks.length} 块内容：\n\n${chunks[chunkIndex]}`;
      
      this.processSingleTextWithFunc(action, chunkWithHeader, (result) => {
        chunkResults.push(result);
        chunkIndex++;
        processNextChunk();
      }, (error) => {
        hasError = true;
        onError(`处理第 ${chunkIndex + 1} 块失败：${error}`);
      });
    };
    
    processNextChunk();
  }
  
  /**
   * 处理合并后的文本
   */
  private processCombinedText(
    action: string,
    combinedText: string,
    pages: AIPageData[],
    onSuccess: (results: AIProcessResult[]) => void,
    onError: (error: string) => void
  ): void {
    const message = this.buildPrompt(action, combinedText);
    
    let result = '';
    
    const actionNames: Record<string, string> = {
      'extract': '提炼',
      'polish': '润色',
      'summarize': '总结',
      'expand': '拓展'
    };
    
    const actionName = actionNames[action] || '处理';
    
    const relatedNotes = pages.map((page): AIRelatedNote => ({
      id: page.id,
      title: page.title
    }));
    
    this.chatStreamWithFunc(
      message,
      (chunk) => {
        if (chunk.content && !chunk.done) {
          result += chunk.content;
        }
      },
      () => {
        const processedResult = result.trim();
        
        const results: AIProcessResult[] = pages.map((page): AIProcessResult => ({
          id: page.id,
          title: page.title,
          result: `【${page.title} - ${actionName}结果】\n\n${processedResult}`
        }));
        
        onSuccess(results);
      },
      (error) => {
        onError(error);
      },
      undefined,
      undefined,
      action,
      '1',
      JSON.stringify(relatedNotes),
      true
    );
  }
  
  /**
   * 使用 func 接口处理单个文本（带重试机制）
   */
  private processSingleTextWithFunc(
    action: string,
    text: string,
    onSuccess: (result: string) => void,
    onError: (error: string) => void,
    retryCount: number = 0
  ): void {
    const message = this.buildPrompt(action, text);
    
    let result = '';
    
    this.chatStreamWithFunc(
      message,
      (chunk) => {
        if (chunk.content && !chunk.done) {
          result += chunk.content;
        }
      },
      () => {
        onSuccess(result.trim());
      },
      (error) => {
        Logger.w('AIService', `处理失败（第${retryCount + 1}次尝试）：${error}`);
        
        if (retryCount < AIService.MAX_RETRY_COUNT) {
          Logger.i('AIService', `${AIService.RETRY_DELAY}ms 后进行第 ${retryCount + 2} 次重试`);
          setTimeout(() => {
            this.processSingleTextWithFunc(action, text, onSuccess, onError, retryCount + 1);
          }, AIService.RETRY_DELAY);
        } else {
          Logger.e('AIService', `已达到最大重试次数 ${AIService.MAX_RETRY_COUNT}，放弃重试`);
          onError(error);
        }
      }
    );
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
    let isCompleted: boolean = false;
    
    const request: AIChatRequest = {
      message: message,
      sessionId: sessionId,
      model: model
    };
    
    const completeWithError = (error: string) => {
      if (isCompleted) {
        return;
      }
      isCompleted = true;
      onError(error);
      httpRequest.destroy();
    };
    
    const completeSuccessfully = () => {
      if (isCompleted) {
        return;
      }
      isCompleted = true;
      onComplete();
      httpRequest.destroy();
    };
    
    httpRequest.on('dataReceive', (data: string | ArrayBuffer) => {
      if (isCompleted) {
        return;
      }
      
      const dataStr: string = typeof data === 'string' ? data : new util.TextDecoder('utf-8').decode(new Uint8Array(data));
      Logger.d('AIService', `收到数据，长度：${dataStr.length}`);
      
      buffer += dataStr;
      
      const lines = buffer.split('\n');
      buffer = lines.pop() || '';
      
      for (const line of lines) {
        if (line.trim().startsWith('data: ')) {
          const dataContent = line.trim().substring(6);
          
          if (dataContent === '[DONE]') {
            Logger.i('AIService', '收到 [DONE] 标记');
            completeSuccessfully();
            return;
          }
          
          try {
            const chunk = JSON.parse(dataContent) as AIStreamChunk;
            Logger.d('AIService', `解析成功 - done: ${chunk.done}`);
            onChunk(chunk);
            
            if (chunk.done || chunk.error) {
              if (chunk.error) {
                completeWithError(chunk.error);
              } else {
                completeSuccessfully();
              }
              return;
            }
          } catch (e) {
            Logger.e('AIService', `解析流数据失败：${e}`);
          }
        }
      }
    });
    
    httpRequest.on('dataEnd', () => {
      Logger.i('AIService', '流式数据接收完毕');
      if (!isCompleted) {
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
        completeSuccessfully();
      }
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
        completeWithError(`请求失败：${err.message}`);
      }
    });
  }
  
  /**
   * 使用 /func 接口进行流式聊天
   */
  public chatStreamWithFunc(
    message: string,
    onChunk: (chunk: AIStreamChunk) => void,
    onComplete: () => void,
    onError: (error: string) => void,
    sessionId?: string,
    model?: string,
    processType?: string,
    userId?: string,
    relatedNotes?: string,
    saveHistory?: boolean
  ): void {
    const url = `${AIService.BASE_URL}${AIService.FUNC_ENDPOINT}`;
    const httpRequest = http.createHttp();
    let buffer: string = '';
    let isCompleted: boolean = false;
    
    const request: AIChatRequest = {
      message: message,
      sessionId: sessionId,
      model: model,
      processType: processType as 'extract' | 'polish' | 'summarize' | 'expand',
      userId: userId,
      relatedNotes: relatedNotes,
      saveHistory: saveHistory
    };
    
    Logger.i('AIService', `========== 开始发送AI请求 ==========`);
    Logger.i('AIService', `请求 URL: ${url}`);
    Logger.i('AIService', `消息长度：${message.length}`);
    Logger.i('AIService', `processType: ${processType}`);
    Logger.i('AIService', `userId: ${userId}`);
    Logger.i('AIService', `saveHistory: ${saveHistory}`);
    Logger.i('AIService', `请求体: ${JSON.stringify(request).substring(0, 500)}...`);
    
    const completeWithError = (error: string) => {
      if (isCompleted) {
        return;
      }
      isCompleted = true;
      Logger.e('AIService', `请求失败：${error}`);
      onError(error);
      httpRequest.destroy();
    };
    
    const completeSuccessfully = () => {
      if (isCompleted) {
        return;
      }
      isCompleted = true;
      Logger.i('AIService', `请求成功完成`);
      onComplete();
      httpRequest.destroy();
    };
    
    httpRequest.on('dataReceive', (data: string | ArrayBuffer) => {
      if (isCompleted) {
        return;
      }
      
      const dataStr: string = typeof data === 'string' ? data : new util.TextDecoder('utf-8').decode(new Uint8Array(data));
      Logger.d('AIService', `收到数据流片段，长度：${dataStr.length}`);
      
      buffer += dataStr;
      
      const lines = buffer.split('\n');
      buffer = lines.pop() || '';
      
      for (const line of lines) {
        if (line.trim().startsWith('data: ')) {
          const dataContent = line.trim().substring(6);
          
          if (dataContent === '[DONE]') {
            Logger.i('AIService', '收到 [DONE] 标记');
            completeSuccessfully();
            return;
          }
          
          try {
            const chunk = JSON.parse(dataContent) as AIStreamChunk;
            Logger.d('AIService', `解析成功 - done: ${chunk.done}, content: ${chunk.content?.substring(0, 50)}...`);
            onChunk(chunk);
            
            if (chunk.done || chunk.error) {
              if (chunk.error) {
                completeWithError(chunk.error);
              } else {
                completeSuccessfully();
              }
              return;
            }
          } catch (e) {
            Logger.e('AIService', `解析流数据失败：${e}`);
          }
        }
      }
    });
    
    httpRequest.on('dataEnd', () => {
      Logger.i('AIService', '流式数据接收完毕');
      if (!isCompleted) {
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
        completeSuccessfully();
      }
    });
        
    Logger.i('AIService', `准备调用 requestInStream`);
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
      Logger.i('AIService', `requestInStream 回调被调用`);
      if (err) {
        Logger.e('AIService', `请求失败：${JSON.stringify(err)}`);
        Logger.e('AIService', `错误代码：${err.code}, 错误消息：${err.message}`);
        completeWithError(`请求失败：${err.message}`);
      } else {
        Logger.i('AIService', `requestInStream 调用成功，没有错误`);
      }
    });
  }
}
