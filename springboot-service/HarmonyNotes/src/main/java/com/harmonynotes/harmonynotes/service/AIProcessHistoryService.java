package com.harmonynotes.harmonynotes.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.harmonynotes.harmonynotes.config.OneDriveConfig;
import com.harmonynotes.harmonynotes.entity.AIProcessHistory;
import com.harmonynotes.harmonynotes.entity.OneDriveToken;
import com.harmonynotes.harmonynotes.mapper.AIProcessHistoryMapper;
import com.harmonynotes.harmonynotes.service.OneDriveAPIService;
import com.harmonynotes.harmonynotes.service.OneDriveTokenService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.task.TaskExecutor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;

@Slf4j
@Service
public class AIProcessHistoryService {
    
    @Autowired
    private AIProcessHistoryMapper historyMapper;
    
    @Autowired
    private ObjectMapper objectMapper;
    
    @Autowired
    private TaskExecutor taskExecutor;
    
    @Autowired
    private OneDriveConfig oneDriveConfig;
    
    @Autowired
    private OneDriveAPIService oneDriveAPIService;
    
    @Autowired
    private OneDriveTokenService tokenService;
    
    private static final DateTimeFormatter FILE_NAME_FORMATTER = DateTimeFormatter.ofPattern("yyyyMMdd_HHmmss_SSS");
    private static final DateTimeFormatter DISPLAY_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
    private static final int MAX_CONTENT_LENGTH = 10 * 1024 * 1024;
    
    public AIProcessHistory saveHistory(AIProcessHistory history) {
        if (history.getContent() != null && history.getContent().length() > MAX_CONTENT_LENGTH) {
            log.warn("AI处理历史内容过长，截断为前 {} 字符", MAX_CONTENT_LENGTH);
            history.setContent(history.getContent().substring(0, MAX_CONTENT_LENGTH));
        }
        
        historyMapper.insert(history);
        log.info("AI处理历史记录已保存，ID: {}, 类型: {}", history.getId(), history.getProcessType());
        
        taskExecutor.execute(() -> {
            try {
                syncToOneDrive(history);
            } catch (Exception e) {
                log.error("同步到 OneDrive 失败: {}", e.getMessage(), e);
            }
        });
        
        return history;
    }
    
    public AIProcessHistory updateHistoryContent(Long id, String content) {
        AIProcessHistory history = new AIProcessHistory();
        history.setId(id);
        history.setContent(content);
        historyMapper.updateContent(history);
        log.info("AI处理历史内容已更新，ID: {}", id);
        
        try {
            AIProcessHistory fullHistory = historyMapper.findById(id);
            if (fullHistory != null) {
                syncToOneDrive(fullHistory);
            }
        } catch (Exception e) {
            log.error("同步更新到 OneDrive 失败: {}", e.getMessage(), e);
        }
        
        return history;
    }
    
    public List<AIProcessHistory> getHistoryByUserId(Long userId) {
        return historyMapper.findByUserId(userId);
    }
    
    public List<AIProcessHistory> getHistoryByUserIdAndType(Long userId, String processType) {
        return historyMapper.findByUserIdAndProcessType(userId, processType);
    }
    
    public AIProcessHistory getHistoryById(Long id) {
        return historyMapper.findById(id);
    }
    
    public void deleteHistory(Long id) {
        AIProcessHistory history = historyMapper.findById(id);
        if (history != null) {
            historyMapper.deleteById(id);
            log.info("AI处理历史记录已删除，ID: {}", id);
            
            try {
                deleteFromOneDrive(history);
            } catch (Exception e) {
                log.error("从 OneDrive 删除失败: {}", e.getMessage(), e);
            }
        }
    }
    
    public void deleteHistoryByUserId(Long userId) {
        List<AIProcessHistory> histories = historyMapper.findByUserId(userId);
        for (AIProcessHistory history : histories) {
            try {
                deleteFromOneDrive(history);
            } catch (Exception e) {
                log.error("从 OneDrive 删除失败: {}", e.getMessage(), e);
            }
        }
        historyMapper.deleteByUserId(userId);
        log.info("用户 {} 的所有AI处理历史记录已删除", userId);
    }
    
    private void syncToOneDrive(AIProcessHistory history) {
        if (history.getProcessType() == null) {
            log.warn("处理类型为空，跳过同步");
            return;
        }
        
        try {
            Long userId = history.getUserId() != null ? history.getUserId() : 1L;
            OneDriveToken token = tokenService.getTokenByUserId(userId);
            
            if (token == null || tokenService.isTokenExpired(token)) {
                log.warn("用户 {} 的 OneDrive 令牌无效或已过期，跳过同步", userId);
                return;
            }
            
            String processType = history.getProcessType();
            String typePath = getProcessTypeName(processType);
            
            String folderPath = oneDriveConfig.getBasePath() + "/aiService/" + typePath;
            boolean folderExists = oneDriveAPIService.checkFolderExists(token.getAccessToken(), folderPath);
            
            if (!folderExists) {
                boolean created = oneDriveAPIService.createFolder(token.getAccessToken(), folderPath);
                if (!created) {
                    log.error("创建 OneDrive 文件夹失败: {}", folderPath);
                    return;
                }
            }
            
            String fileName = String.format("%s%s.json", typePath, history.getCreateTime().format(FILE_NAME_FORMATTER));
            String filePath = folderPath + "/" + fileName;
            
            OneDriveRecord record = new OneDriveRecord();
            record.setName(history.getName());
            record.setCreateTime(history.getCreateTime().format(DISPLAY_FORMATTER));
            record.setRelatedNotes(history.getRelatedNotes());
            record.setContent(history.getContent());
            
            String jsonContent = objectMapper.writerWithDefaultPrettyPrinter().writeValueAsString(record);
            
            boolean uploaded = oneDriveAPIService.uploadFile(token.getAccessToken(), filePath, jsonContent);
            
            if (uploaded) {
                log.info("AI处理历史已同步到 OneDrive: {}", filePath);
            } else {
                log.error("AI处理历史同步到 OneDrive 失败: {}", filePath);
            }
        } catch (Exception e) {
            log.error("同步到 OneDrive 异常: {}", e.getMessage(), e);
        }
    }
    
    private void deleteFromOneDrive(AIProcessHistory history) {
        if (history.getProcessType() == null) {
            return;
        }
        
        try {
            Long userId = history.getUserId() != null ? history.getUserId() : 1L;
            OneDriveToken token = tokenService.getTokenByUserId(userId);
            
            if (token == null || tokenService.isTokenExpired(token)) {
                log.warn("用户 {} 的 OneDrive 令牌无效或已过期，跳过删除", userId);
                return;
            }
            
            String processType = history.getProcessType();
            String typePath = getProcessTypeName(processType);
            
            String fileName = String.format("%s%s.json", typePath, history.getCreateTime().format(FILE_NAME_FORMATTER));
            String filePath = oneDriveConfig.getBasePath() + "/aiService/" + typePath + "/" + fileName;
            
            boolean deleted = oneDriveAPIService.deleteFile(token.getAccessToken(), filePath);
            
            if (deleted) {
                log.info("已从 OneDrive 删除文件: {}", filePath);
            } else {
                log.warn("从 OneDrive 删除文件失败: {}", filePath);
            }
        } catch (Exception e) {
            log.error("从 OneDrive 删除文件异常: {}", e.getMessage(), e);
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
    
    public static class OneDriveRecord {
        private String name;
        private String createTime;
        private String relatedNotes;
        private String content;
        
        public String getName() {
            return name;
        }
        
        public void setName(String name) {
            this.name = name;
        }
        
        public String getCreateTime() {
            return createTime;
        }
        
        public void setCreateTime(String createTime) {
            this.createTime = createTime;
        }
        
        public String getRelatedNotes() {
            return relatedNotes;
        }
        
        public void setRelatedNotes(String relatedNotes) {
            this.relatedNotes = relatedNotes;
        }
        
        public String getContent() {
            return content;
        }
        
        public void setContent(String content) {
            this.content = content;
        }
    }
}
