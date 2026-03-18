package com.harmonynotes.harmonynotes;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
@MapperScan("com.harmonynotes.harmonynotes.mapper")
public class HarmonyNotesApplication {

    public static void main(String[] args) {
        SpringApplication.run(HarmonyNotesApplication.class, args);
    }

}
