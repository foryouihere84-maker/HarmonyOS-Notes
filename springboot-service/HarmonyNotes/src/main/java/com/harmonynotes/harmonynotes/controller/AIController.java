package com.harmonynotes.harmonynotes.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.harmonynotes.harmonynotes.dto.AIChatRequest;
import com.harmonynotes.harmonynotes.dto.AIChatResponse;
import com.harmonynotes.harmonynotes.service.AIService;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;

import java.io.IOException;
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
}
