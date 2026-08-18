package br.com.fiap.flore.repository;

import br.com.fiap.flore.model.ClosetItem;
import br.com.fiap.flore.model.ClosetItemStatus;
import br.com.fiap.flore.model.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ClosetItemRepository extends JpaRepository<ClosetItem, Long> {
    List<ClosetItem> findByOwner(User owner);
    List<ClosetItem> findByStatus(ClosetItemStatus status);
    List<ClosetItem> findByOwnerAndStatus(User owner, ClosetItemStatus status);
}
