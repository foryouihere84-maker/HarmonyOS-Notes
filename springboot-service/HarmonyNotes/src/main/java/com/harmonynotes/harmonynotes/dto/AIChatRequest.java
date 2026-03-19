package com.harmonynotes.harmonynotes.dto;

import lombok.Data;

@Data
public class AIChatRequest {
    private String message;
    private String sessionId;
    private String model;
}
