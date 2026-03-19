package com.harmonynotes.harmonynotes.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.harmonynotes.harmonynotes.dto.AIChatResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.function.Consumer;

@Slf4j
@Service
public class AIService {
    
    @Value("${ai.api.url:https://api.openai.com/v1/chat/completions}")
    private String aiApiUrl;
    
    @Value("${ai.api.key:}")
    private String aiApiKey;
    
    @Value("${ai.api.model:gpt-3.5-turbo}")
    private String defaultModel;
    
    private final ObjectMapper objectMapper;
    
    public AIService() {
        this.objectMapper = new ObjectMapper();
    }
    
    public void chatStream(String message, String sessionId, String model, Consumer<AIChatResponse> onResponse) {
        HttpURLConnection connection = null;
        
        try {
            URL url = new URL(aiApiUrl);
            connection = (HttpURLConnection) url.openConnection();
            connection.setRequestMethod("POST");
            connection.setDoOutput(true);
            connection.setRequestProperty("Content-Type", "application/json");
            connection.setRequestProperty("Accept", "text/event-stream");
            if (aiApiKey != null && !aiApiKey.isEmpty()) {
                connection.setRequestProperty("Authorization", "Bearer " + aiApiKey);
            }
            
            connection.setConnectTimeout(10000);
            connection.setReadTimeout(60000);
            
            log.info("正在调用 AI API: {}", aiApiUrl);
            
            Map<String, Object> requestBody = new HashMap<>();
            requestBody.put("model", model != null ? model : defaultModel);
            requestBody.put("stream", true);
            
            List<Map<String, String>> messages = new java.util.ArrayList<>();
            Map<String, String> userMessage = new HashMap<>();
            userMessage.put("role", "user");
            userMessage.put("content", message);
            messages.add(userMessage);
            requestBody.put("messages", messages);
            
            String jsonRequest = objectMapper.writeValueAsString(requestBody);
            log.debug("请求内容：{}", jsonRequest);
            
            try (var os = connection.getOutputStream()) {
                byte[] input = jsonRequest.getBytes("utf-8");
                os.write(input, 0, input.length);
            }
            
            int httpCode = connection.getResponseCode();
            log.info("AI API 响应码：{}", httpCode);
            
            if (httpCode == 200) {
                try (var reader = new BufferedReader(
                        new InputStreamReader(connection.getInputStream(), "utf-8"))) {
                    
                    String line;
                    int lineCount = 0;
                    while ((line = reader.readLine()) != null) {
                        lineCount++;
                        line = line.trim();
                        if (line.startsWith("data: ")) {
                            String data = line.substring(6).trim();
                            
                            if (data.equals("[DONE]")) {
                                log.info("收到 DONE 信号，已处理{}行数据", lineCount);
                                AIChatResponse doneResponse = new AIChatResponse();
                                doneResponse.setContent(null);
                                doneResponse.setSessionId(sessionId);
                                doneResponse.setModel(model != null ? model : defaultModel);
                                doneResponse.setDone(true);
                                onResponse.accept(doneResponse);
                                break;
                            }
                            
                            if (!data.isEmpty()) {
                                try {
                                    JsonNode jsonNode = objectMapper.readTree(data);
                                    JsonNode choices = jsonNode.path("choices");
                                    
                                    if (choices.isArray() && choices.size() > 0) {
                                        JsonNode delta = choices.get(0).path("delta");
                                        String content = delta.path("content").asText(null);
                                        
                                        if (content != null && !content.isEmpty()) {
                                            AIChatResponse chatResponse = new AIChatResponse();
                                            chatResponse.setContent(content);
                                            chatResponse.setSessionId(sessionId);
                                            chatResponse.setModel(model != null ? model : defaultModel);
                                            chatResponse.setDone(false);
                                            
                                            onResponse.accept(chatResponse);
                                        }
                                    }
                                } catch (Exception e) {
                                    log.error("解析流数据失败：{}", e.getMessage());
                                }
                            }
                        }
                    }
                    log.info("读取完成，共处理{}行数据", lineCount);
                }
            } else {
                log.error("AI API 请求失败：HTTP {}", httpCode);
                AIChatResponse errorResponse = new AIChatResponse();
                errorResponse.setContent(null);
                errorResponse.setSessionId(sessionId);
                errorResponse.setModel(model != null ? model : defaultModel);
                errorResponse.setDone(true);
                errorResponse.setError("AI API 请求失败：HTTP " + httpCode);
                onResponse.accept(errorResponse);
            }
        } catch (Exception e) {
            log.error("AI 服务异常：{}", e.getMessage(), e);
            AIChatResponse errorResponse = new AIChatResponse();
            errorResponse.setContent(null);
            errorResponse.setSessionId(sessionId);
            errorResponse.setModel(model != null ? model : defaultModel);
            errorResponse.setDone(true);
            errorResponse.setError("AI 服务异常：" + e.getMessage());
            onResponse.accept(errorResponse);
        } finally {
            if (connection != null) {
                connection.disconnect();
            }
        }
    }
}
