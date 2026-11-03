-- Teste de fumaça das rotinas PL/SQL: cria dados, chama cada rotina, confere o
-- resultado e desfaz tudo no final (ROLLBACK). Qualquer falha encerra com erro.
SET SERVEROUTPUT ON

DECLARE
    V_USER_ID   NUMBER;
    V_ITEM_ID   NUMBER;
    V_PEDIDO_ID NUMBER;
    V_PERC      NUMBER;
    V_RESUMO    VARCHAR2(4000);
    V_ALERTAS   NUMBER;
    V_AUDIT     NUMBER;
    V_CURSOR    SYS_REFCURSOR;
    V_ACHOU     BOOLEAN := FALSE;
    V_LINHAS    NUMBER := 0;
    R_ID        NUMBER;
    R_COMPRADOR USERS.NOME%TYPE;
    R_PECA      CLOSET_ITEMS.ITEM_NAME%TYPE;
    R_STATUS    PEDIDOS.STATUS%TYPE;
    R_CIDADE    PEDIDOS.CIDADE_DESTINO%TYPE;
    R_DATA      PEDIDOS.DATA_PEDIDO%TYPE;
    R_RISCO     PEDIDOS.RISCO_CLIMATICO%TYPE;

    PROCEDURE confere(p_ok IN BOOLEAN, p_msg IN VARCHAR2) IS
    BEGIN
        IF NOT p_ok THEN
            RAISE_APPLICATION_ERROR(-20900, 'FALHOU: ' || p_msg);
        END IF;
        DBMS_OUTPUT.PUT_LINE('OK  ' || p_msg);
    END;
BEGIN
    INSERT INTO USERS (EMAIL, PASSWORD, NOME)
    VALUES ('smoke.ci@flore.test', 'hash-de-teste', 'Smoke CI')
    RETURNING ID INTO V_USER_ID;

    INSERT INTO CLOSET_ITEMS (ITEM_NAME, CATEGORY, PRICE, OWNER_ID)
    VALUES ('Jaqueta jeans', 'casaco', 89.90, V_USER_ID)
    RETURNING ID INTO V_ITEM_ID;

    PR_REGISTRAR_PEDIDO(V_ITEM_ID, V_USER_ID, 'Sao Paulo');
    SELECT MAX(ID) INTO V_PEDIDO_ID FROM PEDIDOS WHERE COMPRADOR_ID = V_USER_ID;
    confere(V_PEDIDO_ID IS NOT NULL, 'PR_REGISTRAR_PEDIDO criou o pedido');

    V_PERC := FN_PERCENTUAL_PEDIDOS_STATUS('pendente');
    confere(V_PERC > 0, 'FN_PERCENTUAL_PEDIDOS_STATUS = ' || V_PERC || '%');

    V_RESUMO := FN_RESUMO_PEDIDO(V_PEDIDO_ID);
    confere(V_RESUMO LIKE 'Pedido #%Smoke CI%Jaqueta jeans%', 'FN_RESUMO_PEDIDO: ' || V_RESUMO);

    UPDATE PEDIDOS SET RISCO_CLIMATICO = 'S' WHERE ID = V_PEDIDO_ID;
    PR_GERAR_ALERTAS_CLIMA;
    PR_GERAR_ALERTAS_CLIMA; -- segunda chamada nao pode duplicar o alerta
    SELECT COUNT(*) INTO V_ALERTAS FROM ALERTAS_CLIMA WHERE PEDIDO_ID = V_PEDIDO_ID;
    confere(V_ALERTAS = 1, 'PR_GERAR_ALERTAS_CLIMA gerou 1 alerta sem duplicar');

    BEGIN
        PR_REGISTRAR_PEDIDO(V_ITEM_ID, -1, 'Sao Paulo');
        confere(FALSE, 'comprador inexistente deveria ser recusado');
    EXCEPTION
        WHEN OTHERS THEN
            confere(SQLCODE = -20001, 'comprador inexistente recusado (ORA-20001)');
    END;

    -- Fase 7 - package PKG_FLORE: mesmas respostas das rotinas que ele centraliza
    confere(PKG_FLORE.PERCENTUAL_PEDIDOS_STATUS('pendente') = V_PERC,
            'PKG_FLORE.PERCENTUAL_PEDIDOS_STATUS = ' || V_PERC || '%');
    confere(PKG_FLORE.RESUMO_PEDIDO(V_PEDIDO_ID) = FN_RESUMO_PEDIDO(V_PEDIDO_ID), 'PKG_FLORE.RESUMO_PEDIDO');
    PKG_FLORE.GERAR_ALERTAS_CLIMA;
    SELECT COUNT(*) INTO V_ALERTAS FROM ALERTAS_CLIMA WHERE PEDIDO_ID = V_PEDIDO_ID;
    confere(V_ALERTAS = 1, 'PKG_FLORE.GERAR_ALERTAS_CLIMA sem duplicar');

    -- Fase 7 - trigger de auditoria: so registra quando o status muda de fato
    UPDATE CLOSET_ITEMS SET ITEM_STATUS = 'SOLD' WHERE ID = V_ITEM_ID;
    UPDATE CLOSET_ITEMS SET ITEM_STATUS = 'SOLD' WHERE ID = V_ITEM_ID;
    SELECT COUNT(*) INTO V_AUDIT FROM AUDITORIA_CLOSET_ITEMS
    WHERE CLOSET_ITEM_ID = V_ITEM_ID AND STATUS_ANTERIOR = 'AVAILABLE' AND STATUS_NOVO = 'SOLD';
    confere(V_AUDIT = 1, 'TRG_AUDITORIA_CLOSET registrou AVAILABLE -> SOLD uma vez');

    -- Fase 7 - Dynamic SQL: filtros opcionais por cidade e risco climatico
    PR_CONSULTAR_PEDIDOS_DINAMICO(NULL, 'sao paulo', 'S', V_CURSOR);
    LOOP
        FETCH V_CURSOR INTO R_ID, R_COMPRADOR, R_PECA, R_STATUS, R_CIDADE, R_DATA, R_RISCO;
        EXIT WHEN V_CURSOR%NOTFOUND;
        V_LINHAS := V_LINHAS + 1;
        IF R_ID = V_PEDIDO_ID THEN V_ACHOU := TRUE; END IF;
        confere(R_RISCO = 'S', 'PR_CONSULTAR_PEDIDOS_DINAMICO so devolve pedido com risco');
    END LOOP;
    CLOSE V_CURSOR;
    confere(V_ACHOU, 'PR_CONSULTAR_PEDIDOS_DINAMICO achou o pedido (' || V_LINHAS || ' linha)');

    PR_CONSULTAR_PEDIDOS_DINAMICO('ENTREGUE', NULL, NULL, V_CURSOR);
    FETCH V_CURSOR INTO R_ID, R_COMPRADOR, R_PECA, R_STATUS, R_CIDADE, R_DATA, R_RISCO;
    confere(V_CURSOR%NOTFOUND, 'PR_CONSULTAR_PEDIDOS_DINAMICO filtra por status');
    CLOSE V_CURSOR;

    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('Smoke test PL/SQL concluido.');
END;
/
