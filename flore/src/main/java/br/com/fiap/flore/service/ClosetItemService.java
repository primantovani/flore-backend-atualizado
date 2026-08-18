package br.com.fiap.flore.service;

import br.com.fiap.flore.dto.ClosetItemDtos.ClosetItemRequest;
import br.com.fiap.flore.dto.ClosetItemDtos.ClosetItemResponse;
import br.com.fiap.flore.model.ClosetItem;
import br.com.fiap.flore.model.ClosetItemStatus;
import br.com.fiap.flore.model.User;
import br.com.fiap.flore.repository.ClosetItemRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@Service
@RequiredArgsConstructor
public class ClosetItemService {

    private final ClosetItemRepository closetItemRepository;

    // Vitrine do marketplace: só itens ainda disponíveis, de todos os usuários
    // (usado pelo marketplace_screen.dart do Flutter e pelo admin.ts do Angular)
    public List<ClosetItemResponse> listarDisponiveis() {
        return closetItemRepository.findByStatus(ClosetItemStatus.AVAILABLE).stream()
                .map(this::toResponse)
                .toList();
    }

    // Itens do próprio usuário (ex: aba "meu closet" no perfil), incluindo vendidos
    public List<ClosetItemResponse> listarMeus(User dono) {
        return closetItemRepository.findByOwner(dono).stream()
                .map(this::toResponse)
                .toList();
    }

    public ClosetItemResponse buscarPorId(Long id) {
        return toResponse(buscar(id));
    }

    public ClosetItemResponse criar(ClosetItemRequest request, User dono) {
        ClosetItem item = ClosetItem.builder()
                .name(request.name())
                .category(request.category())
                .price(request.price())
                .description(request.description())
                .size(request.size())
                .status(ClosetItemStatus.AVAILABLE)
                .owner(dono)
                .build();

        return toResponse(closetItemRepository.save(item));
    }

    public ClosetItemResponse atualizar(Long id, ClosetItemRequest request, User dono) {
        ClosetItem item = buscarEValidarDono(id, dono);

        item.setName(request.name());
        item.setCategory(request.category());
        item.setPrice(request.price());
        item.setDescription(request.description());
        item.setSize(request.size());

        return toResponse(closetItemRepository.save(item));
    }

    public ClosetItemResponse marcarStatus(Long id, ClosetItemStatus status, User dono) {
        ClosetItem item = buscarEValidarDono(id, dono);
        item.setStatus(status);
        return toResponse(closetItemRepository.save(item));
    }

    // Fluxo de compra (marketplace_screen.dart): qualquer usuário autenticado
    // que NÃO seja o dono pode comprar um item ainda disponível.
    public ClosetItemResponse comprar(Long id, User comprador) {
        ClosetItem item = buscar(id);

        if (item.getOwner().getId().equals(comprador.getId())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Você não pode comprar sua própria peça");
        }
        if (item.getStatus() == ClosetItemStatus.SOLD) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Essa peça já foi vendida");
        }

        item.setStatus(ClosetItemStatus.SOLD);
        return toResponse(closetItemRepository.save(item));
    }

    public void deletar(Long id, User dono) {
        ClosetItem item = buscarEValidarDono(id, dono);
        closetItemRepository.delete(item);
    }

    private ClosetItem buscar(Long id) {
        return closetItemRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Peça não encontrada"));
    }

    private ClosetItem buscarEValidarDono(Long id, User dono) {
        ClosetItem item = buscar(id);
        if (!item.getOwner().getId().equals(dono.getId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Essa peça não pertence a você");
        }
        return item;
    }

    private ClosetItemResponse toResponse(ClosetItem item) {
        String statusStr = item.getStatus() == ClosetItemStatus.SOLD ? "sold" : "available";
        return new ClosetItemResponse(
                item.getId(),
                item.getName(),
                item.getName(),        // nome (alias)
                item.getCategory(),
                item.getCategory(),    // categoria (alias)
                item.getPrice(),
                item.getPrice(),       // preco (alias)
                item.getDescription(),
                item.getSize(),
                item.getSize(),        // tamanho (alias)
                statusStr,
                item.getOwner().getId().toString(),
                item.getOwner().getNome()
        );
    }
}
