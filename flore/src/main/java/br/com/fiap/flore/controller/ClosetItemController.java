package br.com.fiap.flore.controller;

import br.com.fiap.flore.dto.ClosetItemDtos.ClosetItemRequest;
import br.com.fiap.flore.dto.ClosetItemDtos.ClosetItemResponse;
import br.com.fiap.flore.model.ClosetItemStatus;
import br.com.fiap.flore.model.User;
import br.com.fiap.flore.service.ClosetItemService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/closet")
@RequiredArgsConstructor
public class ClosetItemController {

    private final ClosetItemService closetItemService;

    // Marketplace: todas as peças disponíveis (marketplace_screen.dart)
    @GetMapping
    public ResponseEntity<List<ClosetItemResponse>> listarDisponiveis() {
        return ResponseEntity.ok(closetItemService.listarDisponiveis());
    }

    // "Meu closet": peças do usuário logado, incluindo vendidas (profile_screen.dart)
    @GetMapping("/mine")
    public ResponseEntity<List<ClosetItemResponse>> listarMinhas(@AuthenticationPrincipal User user) {
        return ResponseEntity.ok(closetItemService.listarMeus(user));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ClosetItemResponse> buscarPorId(@PathVariable Long id) {
        return ResponseEntity.ok(closetItemService.buscarPorId(id));
    }

    @PostMapping
    public ResponseEntity<ClosetItemResponse> criar(
            @Valid @RequestBody ClosetItemRequest request,
            @AuthenticationPrincipal User user
    ) {
        return ResponseEntity.status(HttpStatus.CREATED).body(closetItemService.criar(request, user));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ClosetItemResponse> atualizar(
            @PathVariable Long id,
            @Valid @RequestBody ClosetItemRequest request,
            @AuthenticationPrincipal User user
    ) {
        return ResponseEntity.ok(closetItemService.atualizar(id, request, user));
    }

    // edit_closet_item_screen.dart: marcar peça como vendida / voltar a disponível
    @PatchMapping("/{id}/status")
    public ResponseEntity<ClosetItemResponse> marcarStatus(
            @PathVariable Long id,
            @RequestParam String status,
            @AuthenticationPrincipal User user
    ) {
        ClosetItemStatus novoStatus = "sold".equalsIgnoreCase(status)
                ? ClosetItemStatus.SOLD
                : ClosetItemStatus.AVAILABLE;

        return ResponseEntity.ok(closetItemService.marcarStatus(id, novoStatus, user));
    }

    // Comprar peça de outro usuário (marketplace_screen.dart -> closetService.buyItem)
    @PostMapping("/{id}/buy")
    public ResponseEntity<ClosetItemResponse> comprar(@PathVariable Long id, @AuthenticationPrincipal User user) {
        return ResponseEntity.ok(closetItemService.comprar(id, user));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deletar(@PathVariable Long id, @AuthenticationPrincipal User user) {
        closetItemService.deletar(id, user);
        return ResponseEntity.noContent().build();
    }
}
