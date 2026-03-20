package com.harmonynotes.harmonynotes.dto;

import lombok.Data;

@Data
public class OneDriveTokenResponse {
    private String access_token;
    private String refresh_token;
    private int expires_in;
    private String token_type;
    private String scope;
}
