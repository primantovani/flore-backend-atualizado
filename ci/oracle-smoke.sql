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

    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('Smoke test PL/SQL concluido.');
END;
/
