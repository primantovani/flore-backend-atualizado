-- Fase 7 - Parte 1 (Gabriel): consulta de pedidos com filtros opcionais (Dynamic SQL).
-- Os filtros entram por bind variables, nunca concatenados na instrucao.

CREATE OR REPLACE PROCEDURE PR_CONSULTAR_PEDIDOS_DINAMICO (
    P_STATUS    IN  VARCHAR2 DEFAULT NULL,
    P_CIDADE    IN  VARCHAR2 DEFAULT NULL,
    P_RISCO     IN  CHAR     DEFAULT NULL,
    P_RESULTADO OUT SYS_REFCURSOR
)
IS
    V_SQL VARCHAR2(4000);
BEGIN
    -- Monta a consulta SQL dinamicamente
    V_SQL := '
        SELECT
            P.ID AS PEDIDO_ID,
            U.NOME AS COMPRADOR,
            C.ITEM_NAME AS PECA,
            P.STATUS,
            P.CIDADE_DESTINO,
            P.DATA_PEDIDO,
            P.RISCO_CLIMATICO
        FROM PEDIDOS P
        INNER JOIN USERS U
            ON U.ID = P.COMPRADOR_ID
        INNER JOIN CLOSET_ITEMS C
            ON C.ID = P.CLOSET_ITEM_ID
        WHERE
            (:B_STATUS IS NULL OR UPPER(P.STATUS) = UPPER(:B_STATUS))
            AND
            (:B_CIDADE IS NULL OR UPPER(P.CIDADE_DESTINO) = UPPER(:B_CIDADE))
            AND
            (:B_RISCO IS NULL OR P.RISCO_CLIMATICO = :B_RISCO)
        ORDER BY P.ID
    ';

    -- Executa a consulta dinamica
    OPEN P_RESULTADO FOR V_SQL
    USING
        P_STATUS, P_STATUS,
        P_CIDADE, P_CIDADE,
        P_RISCO, P_RISCO;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(
            -20010,
            'Erro ao consultar pedidos: ' || SQLERRM
        );
END;
/
