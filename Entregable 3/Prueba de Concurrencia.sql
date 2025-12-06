DECLARE
    v_lives NUMBER;
BEGIN
    
    DBMS_OUTPUT.PUT_LINE('Iniciando Transacción 1...');
    PKG_ACCOUNT.SPEND_LIFE(p_id_user => 1, p_amount => 1);

    DBMS_OUTPUT.PUT_LINE('Vida descontada. Esperando commit...');
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Transacción 1 Finalizada.');
END;
/