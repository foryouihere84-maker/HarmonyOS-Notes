package com.harmonynotes.harmonynotes.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.harmonynotes.harmonynotes.dto.AIChatRequest;
import com.harmonynotes.harmonynotes.dto.AIChatResponse;
import com.harmonynotes.harmonynotes.dto.ApiResponse;
import com.harmonynotes.harmonynotes.entity.AIProcessHistory;
import com.harmonynotes.harmonynotes.service.AIService;
import com.harmonynotes.harmonynotes.service.AIProcessHistoryService;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;

import java.io.IOException;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;

@Slf4j
@RestController
@RequestMapping("/api/v16/ai")
@CrossOrigin(origins = "*")
public class AIController {
    
    @Autowired
    private AIService aiService;
    
    @Autowired
    private ObjectMapper objectMapper;
    
    @Autowired
    private AIProcessHistoryService historyService;
    
    private static final DateTimeFormatter FILE_NAME_FORMATTER = DateTimeFormatter.ofPattern("yyyyMMdd_HHmmss");
    private static final DateTimeFormatter DISPLAY_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
    private static final int MAX_AI_CONTENT_LENGTH = 10 * 1024 * 1024;
    
    @PostMapping(value = "/chat", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public void chatStream(@RequestBody AIChatRequest request, HttpServletResponse response) {
        log.info("收到AI对话请求: sessionId={}, model={}", request.getSessionId(), request.getModel());
        log.info("AI对话内容: {}", request.getMessage());
        response.setContentType(MediaType.TEXT_EVENT_STREAM_VALUE);
        response.setCharacterEncoding("UTF-8");
        response.setHeader("Cache-Control", "no-cache");
        response.setHeader("Connection", "keep-alive");
        
        try {
            aiService.chatStream(
                request.getMessage(),
                request.getSessionId(),
                request.getModel(),
                aiResponse -> {
                    try {
                        String jsonData = objectMapper.writeValueAsString(aiResponse);
                        log.debug("发送数据: {}", jsonData);
                        
                        response.getWriter().write("data: " + jsonData + "\n\n");
                        response.getWriter().flush();
                    } catch (IOException e) {
                        log.error("写入响应失败: {}", e.getMessage());
                    }
                }
            );
            
            response.getWriter().write("data: [DONE]\n\n");
            response.getWriter().flush();
            
        } catch (Exception e) {
            log.error("流式响应失败: {}", e.getMessage(), e);
            try {
                AIChatResponse errorResponse = new AIChatResponse();
                errorResponse.setContent(null);
                errorResponse.setSessionId(request.getSessionId());
                errorResponse.setModel(request.getModel());
                errorResponse.setDone(true);
                errorResponse.setError("服务器错误: " + e.getMessage());
                
                String errorJson = objectMapper.writeValueAsString(errorResponse);
                response.getWriter().write("data: " + errorJson + "\n\n");
                response.getWriter().flush();
            } catch (IOException ex) {
                log.error("发送错误响应失败: {}", ex.getMessage());
            }
        }
    }

    @PostMapping(value = "/func", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public void funcStream(@RequestBody AIChatRequest request, HttpServletResponse response) {
        log.info("收到AI函数请求: sessionId={}, model={}, processType={}", 
            request.getSessionId(), request.getModel(), request.getProcessType());
        log.info("AI函数内容长度: {} 字符", request.getMessage() != null ? request.getMessage().length() : 0);
        
        response.setContentType(MediaType.TEXT_EVENT_STREAM_VALUE);
        response.setCharacterEncoding("UTF-8");
        response.setHeader("Cache-Control", "no-cache");
        response.setHeader("Connection", "keep-alive");
        response.setHeader("X-Accel-Buffering", "no");
        
        StringBuilder aiContentBuilder = new StringBuilder();
        LocalDateTime startTime = LocalDateTime.now();
        
        try {
            log.info("开始处理AI函数请求...");
            
            aiService.funcStream(
                request.getMessage(),
                request.getSessionId(),
                request.getModel(),
                aiResponse -> {
                    try {
                        String jsonData = objectMapper.writeValueAsString(aiResponse);
                        log.debug("发送数据: {}", jsonData);
                        
                        response.getWriter().write("data: " + jsonData + "\n\n");
                        response.getWriter().flush();
                        
                        if (aiResponse.getContent() != null) {
                            if (aiContentBuilder.length() + aiResponse.getContent().length() > MAX_AI_CONTENT_LENGTH) {
                                log.warn("AI 输出内容超过最大限制 {}，停止记录", MAX_AI_CONTENT_LENGTH);
                            } else {
                                aiContentBuilder.append(aiResponse.getContent());
                            }
                        }
                    } catch (IOException e) {
                        log.error("写入响应失败: {}", e.getMessage(), e);
                    }
                }
            );
            
            log.info("AI函数请求处理完成，发送 [DONE] 信号");
            response.getWriter().write("data: [DONE]\n\n");
            response.getWriter().flush();
            
            if (Boolean.TRUE.equals(request.getSaveHistory()) && request.getProcessType() != null) {
                String aiContent = aiContentBuilder.toString();
                log.info("AI 输出总长度: {} 字符", aiContent.length());
                
                try {
                    String processTypeName = getProcessTypeName(request.getProcessType());
                    String name = String.format("%s%s", processTypeName, startTime.format(FILE_NAME_FORMATTER));
                    
                    AIProcessHistory history = new AIProcessHistory();
                    history.setName(name);
                    history.setCreateTime(startTime);
                    history.setRelatedNotes(request.getRelatedNotes());
                    history.setContent(aiContent);
                    history.setProcessType(request.getProcessType());
                    history.setUserId(request.getUserId() != null ? request.getUserId() : 1L);
                    
                    historyService.saveHistory(history);
                    log.info("AI 处理历史记录已保存: {}", name);
                } catch (Exception e) {
                    log.error("保存 AI 处理历史失败: {}", e.getMessage(), e);
                }
            }
            
        } catch (Exception e) {
            log.error("流式响应失败: {}", e.getMessage(), e);
            try {
                AIChatResponse errorResponse = new AIChatResponse();
                errorResponse.setContent(null);
                errorResponse.setSessionId(request.getSessionId());
                errorResponse.setModel(request.getModel());
                errorResponse.setDone(true);
                errorResponse.setError("服务器错误: " + e.getMessage());
                
                String errorJson = objectMapper.writeValueAsString(errorResponse);
                response.getWriter().write("data: " + errorJson + "\n\n");
                response.getWriter().flush();
            } catch (IOException ex) {
                log.error("发送错误响应失败: {}", ex.getMessage(), ex);
            }
        }
    }
    
    private String getProcessTypeName(String processType) {
        switch (processType) {
            case "extract":
                return "提炼";
            case "polish":
                return "润色";
            case "summarize":
                return "总结";
            case "expand":
                return "拓展";
            default:
                return "处理";
        }
    }
    
    @GetMapping("/history")
    public ApiResponse<List<AIProcessHistory>> getHistory(
            @RequestParam(required = false) Long userId,
            @RequestParam(required = false) String processType,
            @RequestParam(required = false, defaultValue = "0") int page,
            @RequestParam(required = false, defaultValue = "100") int size) {
        try {
            if (userId == null) {
                userId = 1L;
            }
            
            if (size > 100) {
                size = 100;
                log.warn("请求的页面大小超过最大限制，设置为 100");
            }
            
            List<AIProcessHistory> histories;
            if (processType != null && !processType.isEmpty()) {
                histories = historyService.getHistoryByUserIdAndType(userId, processType);
            } else {
                histories = historyService.getHistoryByUserId(userId);
            }
            
            int total = histories.size();
            int fromIndex = page * size;
            int toIndex = Math.min(fromIndex + size, total);
            
            if (fromIndex >= total) {
                log.info("请求的页码超出范围，返回空列表");
                return ApiResponse.success(new ArrayList<>());
            }
            
            List<AIProcessHistory> pagedHistories = histories.subList(fromIndex, toIndex);
            
            log.info("获取 AI 处理历史记录成功，用户ID: {}, 类型: {}, 页码: {}, 总数: {}, 返回: {}", 
                userId, processType, page, total, pagedHistories.size());
            
            return ApiResponse.success(pagedHistories);
        } catch (Exception e) {
            log.error("获取 AI 处理历史记录失败: {}", e.getMessage(), e);
            return ApiResponse.error("获取历史记录失败: " + e.getMessage());
        }
    }
    
    @GetMapping("/history/{id}")
    public ApiResponse<AIProcessHistory> getHistoryById(@PathVariable Long id) {
        try {
            AIProcessHistory history = historyService.getHistoryById(id);
            if (history == null) {
                return ApiResponse.error("历史记录不存在");
            }
            
            log.info("获取 AI 处理历史记录成功，ID: {}", id);
            return ApiResponse.success(history);
        } catch (Exception e) {
            log.error("获取 AI 处理历史记录失败: {}", e.getMessage(), e);
            return ApiResponse.error("获取历史记录失败: " + e.getMessage());
        }
    }
    
    @DeleteMapping("/history/{id}")
    public ApiResponse<String> deleteHistory(@PathVariable Long id) {
        try {
            historyService.deleteHistory(id);
            log.info("删除 AI 处理历史记录成功，ID: {}", id);
            return ApiResponse.success("删除成功");
        } catch (Exception e) {
            log.error("删除 AI 处理历史记录失败: {}", e.getMessage(), e);
            return ApiResponse.error("删除失败: " + e.getMessage());
        }
    }
}
