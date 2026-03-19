package com.harmonynotes.harmonynotes.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class AIChatResponse {
    private String content;
    private String sessionId;
    private String model;
    private boolean done;
    private String error;
}
