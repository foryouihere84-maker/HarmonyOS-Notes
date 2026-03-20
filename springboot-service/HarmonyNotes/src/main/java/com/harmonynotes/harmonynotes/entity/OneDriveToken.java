package com.harmonynotes.harmonynotes.entity;

import lombok.Data;
import java.time.LocalDateTime;

@Data
public class OneDriveToken {
    private Long id;
    private Long userId;
    private String accessToken;
    private String refreshToken;
    private LocalDateTime expiresAt;
    private LocalDateTime createdTime;
    private LocalDateTime updatedTime;
}
