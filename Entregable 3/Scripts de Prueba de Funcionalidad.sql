DECLARE
  -- Variables para IDs de usuario
  v_id_giuliano NUMBER;
  v_id_leo      NUMBER;

  -- Variables para IDs de contenido
  v_id_section_1 NUMBER;
  v_id_section_2 NUMBER;
  v_id_page_1    NUMBER;
  v_id_page_2    NUMBER;

  -- Variables para resultados
  v_status_s1      VARCHAR2(20);
  v_status_s2      VARCHAR2(20);
  v_lives_giuliano NUMBER;
  v_lives_leo      NUMBER;
  v_progress_pct   NUMBER;
  v_attempt_id     NUMBER;

BEGIN
  DBMS_OUTPUT.PUT_LINE('--- INICIANDO PRUEBA DE PAQUETES ---');

  -- 1. OBTENER IDs PARA LA PRUEBA (más seguro que hardcodear)
  SELECT ID_USER INTO v_id_giuliano FROM APP_USER WHERE EMAIL = 'giuliano@gmail.com';
  SELECT ID_USER INTO v_id_leo      FROM APP_USER WHERE EMAIL = 'leo@gmail.com';

  SELECT ID_SECTION INTO v_id_section_1 FROM SECTION WHERE NAME = 'Ejecución secuencial e Instrucciones';
  SELECT ID_SECTION INTO v_id_section_2 FROM SECTION WHERE NAME = 'Abstracción de Datos';

  SELECT ID_PAGE INTO v_id_page_1 FROM PAGE WHERE NAME = '¿Qué es un Programa?';
  SELECT ID_PAGE INTO v_id_page_2 FROM PAGE WHERE NAME = 'Ejecución Secuencial';

  DBMS_OUTPUT.PUT_LINE('> IDs de prueba cargados.');
  DBMS_OUTPUT.PUT_LINE('  ID Giuliano: ' || v_id_giuliano);
  DBMS_OUTPUT.PUT_LINE('  ID Leo: ' || v_id_leo);
  DBMS_OUTPUT.PUT_LINE('  ID Sección 1: ' || v_id_section_1);
  DBMS_OUTPUT.PUT_LINE('  ID Página 2: ' || v_id_page_2);

  -- ESCENARIO 1: GIULIANO (Usuario Gratuito) lee y falla la práctica

  DBMS_OUTPUT.PUT_LINE('--- ESCENARIO 1: GIULIANO (Gratuito) ---');

  -- 2. SIMULAR LECTURA (PKG_ACCOUNT y PKG_PROGRESS)
  DBMS_OUTPUT.PUT_LINE('> (Test 1.1) Giuliano lee hasta la página 2...');
  PKG_ACCOUNT.SET_LAST_PAGE(
    p_id_user => v_id_giuliano,
    p_id_page => v_id_page_2
  );

  -- 3. VERIFICAR PROGRESO (PKG_PROGRESS)
  v_progress_pct := PKG_PROGRESS.SECTION_PROGRESS_PCT(
    p_id_user    => v_id_giuliano,
    p_id_section => v_id_section_1
  );
  DBMS_OUTPUT.PUT_LINE('> (Test 1.2) Progreso de Giuliano en S1: ' || v_progress_pct || '%');

  -- 4. SIMULAR PRÁCTICA (FALLIDA) (PKG_PROGRESS)
  DBMS_OUTPUT.PUT_LINE('> (Test 1.3) Giuliano inicia la práctica de S1...');
  v_attempt_id := PKG_PROGRESS.START_ATTEMPT(
    p_id_user    => v_id_giuliano,
    p_id_section => v_id_section_1
  );
  DBMS_OUTPUT.PUT_LINE('> (Test 1.4) ID de intento creado: ' || v_attempt_id);

  DBMS_OUTPUT.PUT_LINE('> (Test 1.5) Giuliano falla la práctica (Score 1)...');
  PKG_PROGRESS.FINISH_ATTEMPT(
    p_id_user    => v_id_giuliano,
    p_id_section => v_id_section_1,
    p_score      => 1
  );

  -- 5. VERIFICAR VIDAS Y ESTADO (PKG_ACCOUNT y PKG_PROGRESS)
  v_lives_giuliano := PKG_ACCOUNT.LIVES_EFFECTIVE(p_id_user => v_id_giuliano);
  v_status_s1 := PKG_PROGRESS.SECTION_STATUS(p_id_user => v_id_giuliano, p_id_section => v_id_section_1);

  DBMS_OUTPUT.PUT_LINE('> (Test 1.6) Vidas restantes de Giuliano: ' || v_lives_giuliano);
  DBMS_OUTPUT.PUT_LINE('> (Test 1.7) Estado de S1 para Giuliano: ' || v_status_s1);

  IF v_lives_giuliano = 4 AND v_status_s1 = 'EN PROGRESO' THEN
    DBMS_OUTPUT.PUT_LINE('>> ESCENARIO 1: EXITOSO (Vidas: 4, Estado: EN PROGRESO)');
  ELSE
    DBMS_OUTPUT.PUT_LINE('>> ESCENARIO 1: FALLIDO');
  END IF;

  -- ESCENARIO 2: LEO (Usuario Premium) aprueba la práctica

  DBMS_OUTPUT.PUT_LINE('--- ESCENARIO 2: LEO (Premium) ---');

  -- 6. SIMULAR PRÁCTICA (APROBADA) (PKG_PROGRESS)
  DBMS_OUTPUT.PUT_LINE('> (Test 2.1) Leo inicia la práctica de S1...');
  v_attempt_id := PKG_PROGRESS.START_ATTEMPT(
    p_id_user    => v_id_leo,
    p_id_section => v_id_section_1
  );

  DBMS_OUTPUT.PUT_LINE('> (Test 2.2) Leo aprueba la práctica (Score 4)...');
  PKG_PROGRESS.FINISH_ATTEMPT(
    p_id_user    => v_id_leo,
    p_id_section => v_id_section_1,
    p_score      => 4 -- (g_pass_threshold es 3)
  );

  -- 7. VERIFICAR VIDAS Y ESTADO (PKG_ACCOUNT y PKG_PROGRESS)
  v_lives_leo := PKG_ACCOUNT.LIVES_EFFECTIVE(p_id_user => v_id_leo);
  v_status_s1 := PKG_PROGRESS.SECTION_STATUS(p_id_user => v_id_leo, p_id_section => v_id_section_1);
  v_status_s2 := PKG_PROGRESS.SECTION_STATUS(p_id_user => v_id_leo, p_id_section => v_id_section_2);

  DBMS_OUTPUT.PUT_LINE('> (Test 2.3) Vidas restantes de Leo: ' || NVL(TO_CHAR(v_lives_leo), 'NULL (Premium)'));
  DBMS_OUTPUT.PUT_LINE('> (Test 2.4) Estado de S1 para Leo: ' || v_status_s1);
  DBMS_OUTPUT.PUT_LINE('> (Test 2.5) Estado de S2 para Leo: ' || v_status_s2);

  IF v_lives_leo IS NULL AND v_status_s1 = 'APROBADO' AND v_status_s2 = 'EN PROGRESO' THEN
    DBMS_OUTPUT.PUT_LINE('>> ESCENARIO 2: EXITOSO (Vidas: Premium, S1: APROBADO, S2: EN PROGRESO)');
  ELSE
    DBMS_OUTPUT.PUT_LINE('>> ESCENARIO 2: FALLIDO');
  END IF;

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('--- PRUEBA FINALIZADA. COMMIT REALIZADO. ---');

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('--- ERROR EN LA PRUEBA: ' || SQLERRM || ' ---');
    ROLLBACK;
END;
/

--Info del usuario
SELECT * FROM V_USER_ACCOUNT_INFO WHERE USERNAME = 'Leo';

--Para probar las vidas
DECLARE
  v_id_giuliano NUMBER;
  v_id_leo      NUMBER;
  v_lives_raw_leo NUMBER;
  v_lives_eff_leo NUMBER;
  v_lives_raw_giu NUMBER;
  v_lives_eff_giu NUMBER;
BEGIN
  SELECT ID_USER INTO v_id_giuliano FROM APP_USER WHERE EMAIL = 'giuliano@gmail.com';
  SELECT ID_USER INTO v_id_leo      FROM APP_USER WHERE EMAIL = 'leo@gmail.com';

  -- Obtener datos de Leo (Premium)
  SELECT LIVES INTO v_lives_raw_leo FROM V_USER_ACCOUNT_INFO WHERE ID_USER = v_id_leo;
  v_lives_eff_leo := PKG_ACCOUNT.LIVES_EFFECTIVE(v_id_leo);

  -- Obtener datos de Giuliano (Gratuito)
  SELECT LIVES INTO v_lives_raw_giu FROM V_USER_ACCOUNT_INFO WHERE ID_USER = v_id_giuliano;
  v_lives_eff_giu := PKG_ACCOUNT.LIVES_EFFECTIVE(v_id_giuliano);

  DBMS_OUTPUT.PUT_LINE('--- PRUEBA LIVES_EFFECTIVE ---');
  DBMS_OUTPUT.PUT_LINE('GIULIANO (Gratis):');
  DBMS_OUTPUT.PUT_LINE('  - Vidas en la tabla (Dato crudo): ' || v_lives_raw_giu);
  DBMS_OUTPUT.PUT_LINE('  - Vidas efectivas (Lógica de negocio): ' || v_lives_eff_giu);

  DBMS_OUTPUT.PUT_LINE('LEO (Premium):');
  DBMS_OUTPUT.PUT_LINE('  - Vidas en la tabla (Dato crudo): ' || v_lives_raw_leo);
  DBMS_OUTPUT.PUT_LINE('  - Vidas efectivas (Lógica de negocio): ' || NVL(TO_CHAR(v_lives_eff_leo), 'NULL (Infinito)'));
END;
/


-- Porbar markdowm

DECLARE
  v_id_section_1   NUMBER;
  v_id_page_1      NUMBER;
  v_page_name      VARCHAR2(200);
  v_page_order     NUMBER;
  v_content_len    NUMBER;
  v_section_check  NUMBER;

  -- Este es el cursor que devuelve el paquete
  rc_pages SYS_REFCURSOR;

BEGIN
  DBMS_OUTPUT.PUT_LINE('--- PRUEBA 1: PKG_CONTENT ---');

  -- 1. Obtener el ID de la Sección 1
  SELECT ID_SECTION
  INTO v_id_section_1
  FROM SECTION
  WHERE NAME = 'Ejecución secuencial e Instrucciones';

  DBMS_OUTPUT.PUT_LINE('> (Test 1.1) Obteniendo páginas para la Sección ' || v_id_section_1);

  -- 2. Probar PKG_CONTENT.SECTION_PAGES
  rc_pages := PKG_CONTENT.SECTION_PAGES(p_id_section => v_id_section_1);

  -- 3. Recorrer el cursor y mostrar las páginas
  LOOP
    FETCH rc_pages INTO v_id_page_1, v_page_name, v_page_order;
    EXIT WHEN rc_pages%NOTFOUND;

    DBMS_OUTPUT.PUT_LINE(
      '  > Página encontrada: (Orden ' || v_page_order ||
      ') (ID ' || v_id_page_1 || ') ' || v_page_name
    );
  END LOOP;
  CLOSE rc_pages;

  -- 4. Probar PKG_CONTENT.PAGE_MARKDOWN (con la última página encontrada)
  v_content_len := DBMS_LOB.GETLENGTH(
    PKG_CONTENT.PAGE_MARKDOWN(p_id_page => v_id_page_1)
  );
  DBMS_OUTPUT.PUT_LINE('> (Test 1.2) Contenido de la página ' || v_id_page_1 || ' cargado. Longitud: ' || v_content_len || ' caracteres.');

  -- 5. Probar PKG_CONTENT.SECTION_OF_PAGE
  v_section_check := PKG_CONTENT.SECTION_OF_PAGE(p_id_page => v_id_page_1);
  DBMS_OUTPUT.PUT_LINE('> (Test 1.3) La página ' || v_id_page_1 || ' pertenece a la sección: ' || v_section_check);

  IF v_content_len > 0 AND v_section_check = v_id_section_1 THEN
    DBMS_OUTPUT.PUT_LINE('>> PRUEBA 1: EXITOSA');
  ELSE
    DBMS_OUTPUT.PUT_LINE('>> PRUEBA 1: FALLIDA');
  END IF;

END;
/

--Para ver la vista de estadisticas de una seccion
SELECT
  u.USERNAME,
  l.NAME AS level_name,
  s.NAME AS section_name,
  v.ATTEMPTS,    -- Corregido (antes era usp.ATTEMPTS)
  v.LAST_SCORE,  -- Corregido (antes era usp.LAST_SCORE)
  v.MAX_SCORE
FROM
  V_USER_SECTION_STATS v
JOIN
  APP_USER u ON v.ID_USER = u.ID_USER
JOIN
  SECTION s ON v.ID_SECTION = s.ID_SECTION
JOIN
  LEVELS l ON v.ID_LEVEL = l.ID_LEVEL
WHERE
  v.ID_SECTION = 1; -- Filtramos por la Sección 1

-- vista para la navegacion
SELECT
  LEVEL_NAME,
  SECTION_NAME,
  PAGE_ORDER,
  PAGE_NAME
FROM
  V_CONTENT_BROWSE
WHERE
  LEVEL_NAME = 'Básico'
ORDER BY
  ID_SECTION, PAGE_ORDER;


--Vista de la pagina principal (dashboard)
DECLARE
  v_id_leo NUMBER;
  v_id_last_page NUMBER;
BEGIN
  DBMS_OUTPUT.PUT_LINE('--- PRUEBA 4: V_USER_DASHBOARD ---');

  -- 1. Obtener IDs
  SELECT ID_USER INTO v_id_leo FROM APP_USER WHERE EMAIL = 'leo@gmail.com';

  SELECT ID_PAGE INTO v_id_last_page
  FROM PAGE
  WHERE NAME = 'Sintaxis y Errores'; -- La última página de la Sección 1

  -- 2. Simular que Leo leyó hasta la última página
  PKG_ACCOUNT.SET_LAST_PAGE(
    p_id_user => v_id_leo,
    p_id_page => v_id_last_page
  );

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('> (Test 4.1) Última página de Leo actualizada a: ' || v_id_last_page);

END;
/

-- 3. Ahora, consulta el Dashboard para Leo
SELECT
  USERNAME,
  HIGHEST_LEVEL_NAME,
  AVG_SCORE_OVERALL,
  SECTIONS_COMPLETED,
  SECTIONS_TOTAL,
  LAST_PAGE_NAME,
  IS_PREMIUM,
  PLAN_NAME
FROM V_USER_DASHBOARD
WHERE ID_USER = (SELECT ID_USER FROM APP_USER WHERE EMAIL = 'leo@gmail.com');

--Probar el sistema de vidas.
DECLARE
  v_id_giuliano NUMBER;
  v_id_section_1 NUMBER;
  v_lives NUMBER;
  v_dummy_attempt_id NUMBER; -- <<< VARIABLE AÑADIDA
BEGIN
  DBMS_OUTPUT.PUT_LINE('--- PRUEBA 5: GASTAR VIDAS (PKG_ACCOUNT) ---');

  SELECT ID_USER INTO v_id_giuliano FROM APP_USER WHERE EMAIL = 'giuliano@gmail.com';
  SELECT ID_SECTION INTO v_id_section_1 FROM SECTION WHERE ID_SECTION = 1;

  -- Simulamos 4 fallos más para gastar las 4 vidas restantes
  DBMS_OUTPUT.PUT_LINE('> (Test 5.1) Gastando 4 vidas restantes...');

  FOR i IN 1..4 LOOP
    -- Inicia y falla la práctica
    -- (Nota: FINISH_ATTEMPT no descuenta vidas, START_ATTEMPT sí)
    v_dummy_attempt_id := PKG_PROGRESS.START_ATTEMPT(  -- <<< LLAMADA CORREGIDA
        p_id_user    => v_id_giuliano,
        p_id_section => v_id_section_1
    );

    PKG_PROGRESS.FINISH_ATTEMPT(
      p_id_user    => v_id_giuliano,
      p_id_section => v_id_section_1,
      p_score      => 1
    );
    v_lives := PKG_ACCOUNT.LIVES_EFFECTIVE(v_id_giuliano);
    DBMS_OUTPUT.PUT_LINE('  > Intento ' || (i+1) || ' realizado. Vidas restantes: ' || v_lives);
  END LOOP;

  COMMIT;

  -- Ahora intentamos iniciar una 6ta práctica (debería fallar)
  DBMS_OUTPUT.PUT_LINE('> (Test 5.2) Intentando iniciar práctica con 0 vidas...');
  BEGIN
    v_dummy_attempt_id := PKG_PROGRESS.START_ATTEMPT( -- <<< LLAMADA CORREGIDA
      p_id_user    => v_id_giuliano,
      p_id_section => v_id_section_1
    );
    DBMS_OUTPUT.PUT_LINE('>> PRUEBA 5: FALLIDA (El sistema dejó iniciar la práctica)');
  EXCEPTION
    WHEN OTHERS THEN
      IF SQLCODE = -20010 THEN
        DBMS_OUTPUT.PUT_LINE('>> PRUEBA 5: EXITOSA (Error capturado: ' || SQLERRM || ')');
      ELSE
        DBMS_OUTPUT.PUT_LINE('>> PRUEBA 5: FALLIDA (Error inesperado: ' || SQLERRM || ')');
      END IF;
  END;

  ROLLBACK; -- Deshacemos el intento fallido
END;
/





--Probar que el usuario no puede iniciar una practica de una seccion que no ha desbloqueado
DECLARE
  v_id_giuliano NUMBER;
  v_id_section_2 NUMBER;
  v_can_start CHAR(1);
  v_dummy_attempt_id NUMBER; -- <<< VARIABLE AÑADIDA
BEGIN
  DBMS_OUTPUT.PUT_LINE('--- PRUEBA 6: LÓGICA DE BLOQUEO (PKG_PROGRESS) ---');

  SELECT ID_USER INTO v_id_giuliano FROM APP_USER WHERE EMAIL = 'giuliano@gmail.com';
  SELECT ID_SECTION INTO v_id_section_2 FROM SECTION WHERE NAME = 'Abstracción de Datos'; -- Sección 2

  -- 1. Verificar si PUEDE empezar
  v_can_start := PKG_PROGRESS.CAN_START_PRACTICE(v_id_giuliano, v_id_section_2);
  DBMS_OUTPUT.PUT_LINE('> (Test 6.1) ¿Puede Giuliano iniciar S2? (Respuesta: ' || v_can_start || ')');

  -- 2. Intentar empezar (debería fallar)
  DBMS_OUTPUT.PUT_LINE('> (Test 6.2) Intentando iniciar práctica de S2 (BLOQUEADO)...');
  BEGIN
    v_dummy_attempt_id := PKG_PROGRESS.START_ATTEMPT( -- <<< LLAMADA CORREGIDA
      p_id_user    => v_id_giuliano,
      p_id_section => v_id_section_2
    );
    DBMS_OUTPUT.PUT_LINE('>> PRUEBA 6: FALLIDA (El sistema dejó iniciar la práctica)');
  EXCEPTION
    WHEN OTHERS THEN
      IF SQLCODE = -20020 THEN
        DBMS_OUTPUT.PUT_LINE('>> PRUEBA 6: EXITOSA (Error capturado: ' || SQLERRM || ')');
      ELSE
        DBMS_OUTPUT.PUT_LINE('>> PRUEBA 6: FALLIDA (Error inesperado: ' || SQLERRM || ')');
      END IF;
  END;

END;
/





--Regresar las vidas de giuliano
DECLARE
  v_id_giuliano NUMBER;
  v_lives_antes NUMBER;
  v_lives_despues NUMBER;
BEGIN
  DBMS_OUTPUT.PUT_LINE('--- PRUEBA 7: RECARGA DE VIDAS (PKG_ACCOUNT) ---');

  SELECT ID_USER INTO v_id_giuliano FROM APP_USER WHERE EMAIL = 'giuliano@gmail.com';

  -- 1. Verificamos vidas (deberían ser 0)
  v_lives_antes := PKG_ACCOUNT.LIVES_EFFECTIVE(v_id_giuliano);
  DBMS_OUTPUT.PUT_LINE('> (Test 7.1) Vidas antes del viaje en el tiempo: ' || v_lives_antes);

  -- 2. "Viaje en el tiempo" (Simulamos que su recarga era hace 1 día)
  UPDATE USER_ACCOUNT
  SET NEXT_LIFE_AT = SYSDATE - 1
  WHERE ID_USER = v_id_giuliano;
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('> (Test 7.2) ¡Viajando 1 día al pasado... ZAP!');

  -- 3. Pedir vidas de nuevo. La función llamará a REFRESH_LIVES
  v_lives_despues := PKG_ACCOUNT.LIVES_EFFECTIVE(v_id_giuliano);
  DBMS_OUTPUT.PUT_LINE('> (Test 7.3) Vidas después del viaje: ' || v_lives_despues);

  IF v_lives_antes = 0 AND v_lives_despues = 5 THEN
     DBMS_OUTPUT.PUT_LINE('>> PRUEBA 7: EXITOSA (Vidas recargadas a 5)');
  ELSE
     DBMS_OUTPUT.PUT_LINE('>> PRUEBA 7: FALLIDA');
  END IF;

  COMMIT;
END;
/





--TRG_APP_USER_TOUCH
DECLARE
  v_id_giuliano NUMBER;
  v_time_before DATE;
  v_time_after  DATE;
BEGIN
  DBMS_OUTPUT.PUT_LINE('--- PRUEBA 8.1: TRIGGER TRG_APP_USER_TOUCH ---');
  SELECT ID_USER INTO v_id_giuliano FROM APP_USER WHERE EMAIL = 'giuliano@gmail.com';

  -- 1. Obtenemos el tiempo actual
  SELECT UPDATED_AT INTO v_time_before FROM APP_USER WHERE ID_USER = v_id_giuliano;
  DBMS_OUTPUT.PUT_LINE('> (Test 8.1) UPDATED_AT (Antes): ' || TO_CHAR(v_time_before, 'HH24:MI:SS'));

  -- 2. Esperamos 2 segundos y hacemos un UPDATE
  DBMS_SESSION.SLEEP(2);
  UPDATE APP_USER SET USERNAME = 'Giuliano A.' WHERE ID_USER = v_id_giuliano;
  COMMIT;

  -- 3. Verificamos el nuevo tiempo
  SELECT UPDATED_AT INTO v_time_after FROM APP_USER WHERE ID_USER = v_id_giuliano;
  DBMS_OUTPUT.PUT_LINE('> (Test 8.2) UPDATED_AT (Después): ' || TO_CHAR(v_time_after, 'HH24:MI:SS'));

  IF v_time_after > v_time_before THEN
    DBMS_OUTPUT.PUT_LINE('>> PRUEBA 8.1: EXITOSA (El trigger actualizó la fecha)');
  ELSE
    DBMS_OUTPUT.PUT_LINE('>> PRUEBA 8.1: FALLIDA');
  END IF;

  -- Revertir el cambio
  UPDATE APP_USER SET USERNAME = 'Giuliano' WHERE ID_USER = v_id_giuliano;
  COMMIT;
END;
/


--TRG_SUBSCRIPTION_DATES
BEGIN
  DBMS_OUTPUT.PUT_LINE('--- PRUEBA 8.2: TRIGGER TRG_SUBSCRIPTION_DATES ---');
  DBMS_OUTPUT.PUT_LINE('> (Test 8.2) Intentando registrar una suscripción con END_DATE < START_DATE...');

  -- Intentamos insertar una suscripción inválida
  INSERT INTO SUBSCRIPTION(ID_USER, ID_PLAN, START_DATE, END_DATE, STATUS)
  VALUES (
    (SELECT ID_USER FROM APP_USER WHERE EMAIL = 'giuliano@gmail.com'),
    1,
    SYSDATE,         -- Start Date
    SYSDATE - 1,     -- End Date (INVÁLIDO)
    'ACTIVO'
  );

  DBMS_OUTPUT.PUT_LINE('>> PRUEBA 8.2: FALLIDA (El trigger dejó insertar la fecha inválida)');
  ROLLBACK;
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE = -20001 THEN
      DBMS_OUTPUT.PUT_LINE('>> PRUEBA 8.2: EXITOSA (Error capturado: ' || SQLERRM || ')');
    ELSE
      DBMS_OUTPUT.PUT_LINE('>> PRUEBA 8.2: FALLIDA (Error inesperado: ' || SQLERRM || ')');
    END IF;
    ROLLBACK;
END;
/