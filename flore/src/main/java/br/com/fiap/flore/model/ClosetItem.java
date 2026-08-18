package br.com.fiap.flore.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "closet_items")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ClosetItem {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;

    // ex: camiseta, calca, vestido, casaco, sapato...
    @Column(nullable = false)
    private String category;

    @Column(nullable = false)
    private Double price;

    @Column(length = 1000)
    private String description;

    // Usado pelo painel admin em Angular (campo "tamanho"). Opcional pro Flutter.
    private String size;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    @Builder.Default
    private ClosetItemStatus status = ClosetItemStatus.AVAILABLE;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "owner_id", nullable = false)
    private User owner;
}
