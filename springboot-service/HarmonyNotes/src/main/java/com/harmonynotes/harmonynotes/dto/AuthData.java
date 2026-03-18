package com.harmonynotes.harmonynotes.dto;

import lombok.Data;

@Data
public class AuthData {
    private UserDTO user;
    private String token;
}
