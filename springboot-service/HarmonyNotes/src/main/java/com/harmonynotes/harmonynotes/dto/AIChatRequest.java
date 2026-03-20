package com.harmonynotes.harmonynotes.dto;

import lombok.Data;

@Data
public class AIChatRequest {
    private String message;
    private String sessionId;
    private String model;
    private String processType;
    private Long userId;
    private String relatedNotes;
    private Boolean saveHistory;
}
