package br.com.fiap.flore.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public class AuthDtos {

    // Flutter chama POST /api/auth/signup com {name, email, password}
    public record SignupRequest(
            @NotBlank String name,
            @Email @NotBlank String email,
            @Size(min = 6, message = "senha deve ter no mínimo 6 caracteres") String password
    ) {}

    public record LoginRequest(
            @Email @NotBlank String email,
            @NotBlank String password
    ) {}

    public record ProfileUpdateRequest(
            @NotBlank String name,
            @Email @NotBlank String email
    ) {}

    public record ForgotPasswordRequest(
            @Email @NotBlank String email
    ) {}

    // Espelha o AppUser.fromJson() do Flutter
    public record UserResponse(
            Long id,
            String name,
            String email
    ) {}

    // AuthService._persistSession espera exatamente {token, user: {...}}
    public record AuthResponse(
            String token,
            UserResponse user
    ) {}

    // updateProfile aceita tanto {user: {...}} quanto o objeto flat - respondemos aninhado
    public record ProfileResponse(
            UserResponse user
    ) {}
}
