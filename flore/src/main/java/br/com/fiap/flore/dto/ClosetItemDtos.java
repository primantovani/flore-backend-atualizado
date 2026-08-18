package br.com.fiap.flore.dto;

import com.fasterxml.jackson.annotation.JsonAlias;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;

public class ClosetItemDtos {

    // Aceita tanto o formato do Flutter (name/category/price) quanto do
    // Angular admin (nome/categoria/preco) - @JsonAlias permite os dois.
    public record ClosetItemRequest(
            @NotBlank @JsonAlias("nome") String name,
            @NotBlank @JsonAlias("categoria") String category,
            @NotNull @PositiveOrZero @JsonAlias("preco") Double price,
            String description,
            @JsonAlias("tamanho") String size
    ) {}

    // Responde com as duas nomenclaturas (name+nome, category+categoria,
    // price+preco) pra nao depender de qual frontend esta lendo.
    public record ClosetItemResponse(
            Long id,
            String name,
            String nome,
            String category,
            String categoria,
            Double price,
            Double preco,
            String description,
            String size,
            String tamanho,
            String status,      // "available" | "sold"
            String ownerId,
            String ownerName
    ) {}
}
