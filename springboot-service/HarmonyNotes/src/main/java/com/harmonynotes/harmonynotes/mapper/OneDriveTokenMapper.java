package com.harmonynotes.harmonynotes.mapper;

import com.harmonynotes.harmonynotes.entity.OneDriveToken;
import org.apache.ibatis.annotations.*;

@Mapper
public interface OneDriveTokenMapper {
    
    @Insert("INSERT INTO onedrive_token (user_id, access_token, refresh_token, expires_at, created_time, updated_time) " +
            "VALUES (#{userId}, #{accessToken}, #{refreshToken}, #{expiresAt}, NOW(), NOW())")
    @Options(useGeneratedKeys = true, keyProperty = "id")
    int insert(OneDriveToken token);
    
    @Select("SELECT * FROM onedrive_token WHERE user_id = #{userId} ORDER BY updated_time DESC LIMIT 1")
    OneDriveToken findByUserId(Long userId);
    
    @Update("UPDATE onedrive_token SET access_token = #{accessToken}, refresh_token = #{refreshToken}, expires_at = #{expiresAt}, updated_time = NOW() WHERE id = #{id}")
    int update(OneDriveToken token);
    
    @Delete("DELETE FROM onedrive_token WHERE user_id = #{userId}")
    int deleteByUserId(Long userId);
}
