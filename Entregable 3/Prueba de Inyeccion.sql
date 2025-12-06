DECLARE
  v_user_id NUMBER;
  v_email_malicioso VARCHAR2(200) := 'alonso@gmail.com''; DROP TABLE APP_USER; --'; 
BEGIN
  -- Al usar el paquete, Oracle trata el input como un literal de texto, 
  -- NO como código ejecutable.
  PKG_USER_REGISTRATION.HANDLE_GOOGLE_LOGIN(
    p_email => v_email_malicioso,
    p_google_name => 'alonso',
    p_google_id => '12345',
    p_birth_date => SYSDATE,
    p_id_user => v_user_id
  );
  
  DBMS_OUTPUT.PUT_LINE('Usuario creado/login seguro. ID: ' || v_user_id);
  DBMS_OUTPUT.PUT_LINE('El email se guardó textualmente, no se ejecutó el DROP TABLE.');
END;
/

-- Verificación:
SELECT EMAIL FROM APP_USER WHERE EMAIL LIKE '%DROP TABLE%';