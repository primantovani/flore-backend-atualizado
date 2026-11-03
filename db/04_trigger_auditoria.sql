-- Fase 7 - Parte 1 (Gabriel): auditoria das mudancas de status das pecas.
-- A tabela segue o padrao de 01_tabelas.sql (ignora ORA-00955 se ja existir).

DECLARE
    PROCEDURE criar(p_ddl IN VARCHAR2) IS
    BEGIN
        EXECUTE IMMEDIATE p_ddl;
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -955 THEN
                NULL;
            ELSE
                RAISE;
            END IF;
    END;
BEGIN
    criar(q'[
        CREATE TABLE AUDITORIA_CLOSET_ITEMS (
            ID NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            CLOSET_ITEM_ID NUMBER NOT NULL,
            STATUS_ANTERIOR VARCHAR2(20),
            STATUS_NOVO VARCHAR2(20),
            DATA_ALTERACAO DATE DEFAULT SYSDATE NOT NULL,
            USUARIO_BANCO VARCHAR2(100),
            CONSTRAINT FK_AUDITORIA_CLOSET
                FOREIGN KEY (CLOSET_ITEM_ID)
                REFERENCES CLOSET_ITEMS (ID)
        )]');
END;
/

CREATE OR REPLACE TRIGGER TRG_AUDITORIA_CLOSET
AFTER UPDATE OF ITEM_STATUS
ON CLOSET_ITEMS
FOR EACH ROW
BEGIN
    -- Verifica se realmente houve alteracao
    IF :OLD.ITEM_STATUS <> :NEW.ITEM_STATUS THEN
        INSERT INTO AUDITORIA_CLOSET_ITEMS (
            CLOSET_ITEM_ID,
            STATUS_ANTERIOR,
            STATUS_NOVO,
            DATA_ALTERACAO,
            USUARIO_BANCO
        )
        VALUES (
            :OLD.ID,
            :OLD.ITEM_STATUS,
            :NEW.ITEM_STATUS,
            SYSDATE,
            SYS_CONTEXT('USERENV', 'SESSION_USER')
        );
    END IF;
END;
/
