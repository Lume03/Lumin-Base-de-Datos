-- ESPECIFICACIONES DE PAQUETES (SPECS)

CREATE OR REPLACE PACKAGE PKG_SUBSCRIPTION AS
  FUNCTION IS_ACTIVE(p_id_user IN NUMBER) RETURN CHAR;
  PROCEDURE REGISTER_SUBSCRIPTION(
    p_id_user    IN NUMBER,
    p_id_plan    IN NUMBER,
    p_start_date IN DATE DEFAULT TRUNC(SYSDATE)
  );
END PKG_SUBSCRIPTION;
/

CREATE OR REPLACE PACKAGE PKG_AUTH AS
  PROCEDURE SYNC_EXTERNAL(
    p_id_user     IN NUMBER,
    p_provider    IN VARCHAR2,
    p_provider_id IN VARCHAR2
  );
END PKG_AUTH;
/

CREATE OR REPLACE PACKAGE PKG_ACCOUNT AS
  FUNCTION IS_PREMIUM(p_id_user IN NUMBER) RETURN CHAR;
  PROCEDURE SPEND_LIFE(p_id_user IN NUMBER, p_amount IN NUMBER DEFAULT 1);
  PROCEDURE SET_LAST_PAGE(p_id_user IN NUMBER, p_id_page IN NUMBER);
  FUNCTION  LIVES_EFFECTIVE(p_id_user IN NUMBER) RETURN NUMBER;
  PROCEDURE REFRESH_LIVES(p_id_user IN NUMBER);
  PROCEDURE CREATE_DEFAULT_ACCOUNT(p_id_user IN NUMBER);
END PKG_ACCOUNT;
/

CREATE OR REPLACE PACKAGE PKG_CONTENT AS
  FUNCTION SECTION_PAGES(p_id_section IN NUMBER) RETURN SYS_REFCURSOR;
  FUNCTION PAGE_MARKDOWN(p_id_page IN NUMBER) RETURN CLOB;
  FUNCTION SECTION_OF_PAGE(p_id_page IN NUMBER) RETURN NUMBER;
END PKG_CONTENT;
/

CREATE OR REPLACE PACKAGE PKG_PROGRESS AS
  g_pass_threshold CONSTANT NUMBER := 3;

  FUNCTION SECTION_STATUS(p_id_user IN NUMBER, p_id_section IN NUMBER)
    RETURN VARCHAR2;
  PROCEDURE ENSURE_ROW(p_id_user IN NUMBER, p_id_section IN NUMBER);
  FUNCTION CAN_START_PRACTICE(p_id_user IN NUMBER, p_id_section IN NUMBER)
    RETURN CHAR;
  FUNCTION START_ATTEMPT(p_id_user IN NUMBER, p_id_section IN NUMBER)
    RETURN NUMBER;
  PROCEDURE FINISH_ATTEMPT(
    p_id_user    IN NUMBER,
    p_id_section IN NUMBER,
    p_score      IN NUMBER
  );
  FUNCTION SECTION_PROGRESS_PCT(
    p_id_user    IN NUMBER,
    p_id_section IN NUMBER
  ) RETURN NUMBER;
END PKG_PROGRESS;
/

CREATE OR REPLACE PACKAGE PKG_USER_REGISTRATION AS
  PROCEDURE HANDLE_GOOGLE_LOGIN(
    p_email       IN VARCHAR2,
    p_google_name IN VARCHAR2,
    p_google_id   IN VARCHAR2,
    p_id_user     OUT NUMBER
  );
  PROCEDURE INITIALIZE_PROGRESS(
    p_id_user IN NUMBER
  );
END PKG_USER_REGISTRATION;
/

-- CUERPOS DE PAQUETES (los body)

CREATE OR REPLACE PACKAGE BODY PKG_SUBSCRIPTION AS
  FUNCTION IS_ACTIVE(p_id_user IN NUMBER) RETURN CHAR IS
    v_cnt NUMBER;
  BEGIN
    SELECT COUNT(*)
      INTO v_cnt
      FROM V_ACTIVE_SUBSCRIPTION
     WHERE ID_USER = p_id_user;
    RETURN CASE WHEN v_cnt > 0 THEN 'S' ELSE 'N' END;
  END;

  PROCEDURE REGISTER_SUBSCRIPTION(
    p_id_user    IN NUMBER,
    p_id_plan    IN NUMBER,
    p_start_date IN DATE
  ) IS
    v_days  SUBSCRIPTION_PLAN.DURATION_DAYS%TYPE;
  BEGIN
    SELECT DURATION_DAYS INTO v_days
      FROM SUBSCRIPTION_PLAN
     WHERE ID_PLAN = p_id_plan;

    INSERT INTO SUBSCRIPTION(ID_USER, ID_PLAN, START_DATE, END_DATE, STATUS)
    VALUES (p_id_user, p_id_plan, TRUNC(p_start_date), TRUNC(p_start_date)+v_days, 'ACTIVO');
  END;
END PKG_SUBSCRIPTION;
/

CREATE OR REPLACE PACKAGE BODY PKG_AUTH AS
  PROCEDURE SYNC_EXTERNAL(
    p_id_user     IN NUMBER,
    p_provider    IN VARCHAR2,
    p_provider_id IN VARCHAR2
  ) IS
  BEGIN
    MERGE INTO EXTERNAL_AUTH t
    USING (SELECT p_id_user id_user, p_provider provider, p_provider_id provider_id FROM DUAL) s
       ON (t.PROVIDER = s.provider AND t.PROVIDER_ID = s.provider_id)
    WHEN MATCHED THEN
      UPDATE SET t.ID_USER = s.id_user
    WHEN NOT MATCHED THEN
      INSERT (ID_USER, PROVIDER, PROVIDER_ID, CREATED_AT)
      VALUES (s.id_user, s.provider, s.provider_id, SYSDATE);
  END;
END PKG_AUTH;
/

CREATE OR REPLACE PACKAGE BODY PKG_ACCOUNT AS
  FUNCTION IS_PREMIUM(p_id_user IN NUMBER) RETURN CHAR IS
  BEGIN
    RETURN PKG_SUBSCRIPTION.IS_ACTIVE(p_id_user);
  END;

  PROCEDURE REFRESH_LIVES(p_id_user IN NUMBER) IS
    v_is_premium   CHAR(1);
    v_lives        USER_ACCOUNT.LIVES%TYPE;
    v_next         USER_ACCOUNT.NEXT_LIFE_AT%TYPE;
    v_to_add       NUMBER;
    v_cap          NUMBER;
    v_minutes      NUMBER;
    v_new_lives    NUMBER;
    v_new_next     DATE;
  BEGIN
    v_is_premium := IS_PREMIUM(p_id_user);
    IF v_is_premium = 'S' THEN
      RETURN;
    END IF;

    BEGIN
      SELECT LIVES, NEXT_LIFE_AT
        INTO v_lives, v_next
        FROM USER_ACCOUNT
       WHERE ID_USER = p_id_user
       FOR UPDATE;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        CREATE_DEFAULT_ACCOUNT(p_id_user);
        SELECT LIVES, NEXT_LIFE_AT
          INTO v_lives, v_next
          FROM USER_ACCOUNT
         WHERE ID_USER = p_id_user
         FOR UPDATE;
    END;

    IF v_lives >= 5 THEN
      IF v_next IS NOT NULL THEN
        UPDATE USER_ACCOUNT SET NEXT_LIFE_AT = NULL WHERE ID_USER = p_id_user;
      END IF;
      RETURN;
    END IF;

    IF v_next IS NULL THEN
      RETURN;
    END IF;

    IF v_next > SYSDATE THEN
      RETURN;
    END IF;

    v_minutes := FLOOR( (SYSDATE - v_next) * 24 * 60 );
    v_to_add  := 1 + FLOOR(v_minutes / 120);
    v_cap       := LEAST(v_to_add, 5 - v_lives);
    v_new_lives := v_lives + v_cap;

    IF v_new_lives >= 5 THEN
      v_new_next := NULL;
    ELSE
      v_new_next := v_next + NUMTODSINTERVAL(v_cap * 120, 'MINUTE');
    END IF;

    UPDATE USER_ACCOUNT
       SET LIVES       = v_new_lives,
           NEXT_LIFE_AT= v_new_next
     WHERE ID_USER     = p_id_user;
  END;

  PROCEDURE SPEND_LIFE(p_id_user IN NUMBER, p_amount IN NUMBER) IS
    v_is_premium CHAR(1);
    v_lives      USER_ACCOUNT.LIVES%TYPE;
    v_next       USER_ACCOUNT.NEXT_LIFE_AT%TYPE;
    v_new_lives  NUMBER;
    v_new_next   DATE;
  BEGIN
    v_is_premium := IS_PREMIUM(p_id_user);
    IF v_is_premium = 'S' THEN
      RETURN;
    END IF;

    REFRESH_LIVES(p_id_user);

    SELECT LIVES, NEXT_LIFE_AT
      INTO v_lives, v_next
      FROM USER_ACCOUNT
     WHERE ID_USER = p_id_user
     FOR UPDATE;

    IF v_lives < p_amount THEN
      RAISE_APPLICATION_ERROR(-20010, 'No tienes mas vidas');
    END IF;

    v_new_lives := v_lives - p_amount;
    IF v_new_lives < 5 THEN
      v_new_next := COALESCE(v_next, SYSDATE + NUMTODSINTERVAL(120,'MINUTE'));
    ELSE
      v_new_next := NULL;
    END IF;

    UPDATE USER_ACCOUNT
       SET LIVES        = v_new_lives,
           NEXT_LIFE_AT = v_new_next
     WHERE ID_USER      = p_id_user;
  END;

  PROCEDURE SET_LAST_PAGE(p_id_user IN NUMBER, p_id_page IN NUMBER) IS
  BEGIN
    MERGE INTO USER_ACCOUNT a
    USING (SELECT p_id_user id_user, p_id_page id_page FROM DUAL) s
       ON (a.ID_USER = s.id_user)
    WHEN MATCHED THEN
      UPDATE SET a.ID_PAGE = s.id_page
    WHEN NOT MATCHED THEN
      INSERT (ID_USER, LIVES, ID_PAGE, NEXT_LIFE_AT)
      VALUES (s.id_user, 5, s.id_page, NULL);
  END;

  FUNCTION LIVES_EFFECTIVE(p_id_user IN NUMBER) RETURN NUMBER IS
    v_is_premium CHAR(1);
    v_lives      NUMBER;
  BEGIN
    v_is_premium := IS_PREMIUM(p_id_user);
    IF v_is_premium = 'S' THEN
      RETURN NULL;
    END IF;

    REFRESH_LIVES(p_id_user);

    SELECT LIVES INTO v_lives FROM USER_ACCOUNT WHERE ID_USER = p_id_user;
    RETURN v_lives;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      CREATE_DEFAULT_ACCOUNT(p_id_user);
      RETURN 5;
  END;

  PROCEDURE CREATE_DEFAULT_ACCOUNT(p_id_user IN NUMBER) IS
  BEGIN
    MERGE INTO USER_ACCOUNT a
    USING (SELECT p_id_user id_user FROM DUAL) s
       ON (a.ID_USER = s.id_user)
    WHEN NOT MATCHED THEN
      INSERT (ID_USER, LIVES, ID_PAGE, NEXT_LIFE_AT)
      VALUES (s.id_user, 5, NULL, NULL);
  END;
END PKG_ACCOUNT;
/

CREATE OR REPLACE PACKAGE BODY PKG_CONTENT AS
  FUNCTION SECTION_PAGES(p_id_section IN NUMBER) RETURN SYS_REFCURSOR IS
    rc SYS_REFCURSOR;
  BEGIN
    OPEN rc FOR
      SELECT p.ID_PAGE, p.NAME, p.PAGE_ORDER
        FROM THEORY_MODULE tm
        JOIN PAGE p ON p.ID_THEORY_MODULE = tm.ID_THEORY_MODULE
       WHERE tm.ID_SECTION = p_id_section
       ORDER BY p.PAGE_ORDER;
    RETURN rc;
  END;

  FUNCTION PAGE_MARKDOWN(p_id_page IN NUMBER) RETURN CLOB IS
    v_md CLOB;
  BEGIN
    SELECT CONTENT_MD INTO v_md
      FROM PAGE
     WHERE ID_PAGE = p_id_page;
    RETURN v_md;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN NULL;
  END;

  FUNCTION SECTION_OF_PAGE(p_id_page IN NUMBER) RETURN NUMBER IS
    v_section NUMBER;
  BEGIN
    SELECT tm.ID_SECTION
      INTO v_section
      FROM PAGE p
      JOIN THEORY_MODULE tm ON tm.ID_THEORY_MODULE = p.ID_THEORY_MODULE
     WHERE p.ID_PAGE = p_id_page;
    RETURN v_section;
  END;
END PKG_CONTENT;
/

CREATE OR REPLACE PACKAGE BODY PKG_PROGRESS AS
  FUNCTION SECTION_STATUS(p_id_user IN NUMBER, p_id_section IN NUMBER)
    RETURN VARCHAR2 IS
    v_status USER_SECTION_PROGRESS.STATUS%TYPE;
  BEGIN
    SELECT STATUS INTO v_status
      FROM USER_SECTION_PROGRESS
     WHERE ID_USER = p_id_user AND ID_SECTION = p_id_section;
    RETURN v_status;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN 'BLOQUEADO';
  END;

  PROCEDURE ENSURE_ROW(p_id_user IN NUMBER, p_id_section IN NUMBER) IS
    v_cnt NUMBER;
    v_prev_section NUMBER;
  BEGIN
    SELECT COUNT(*) INTO v_cnt
      FROM USER_SECTION_PROGRESS
     WHERE ID_USER = p_id_user AND ID_SECTION = p_id_section;

    IF v_cnt = 0 THEN
      BEGIN
        SELECT s2.ID_SECTION
          INTO v_prev_section
          FROM SECTION s1
          JOIN SECTION s2
            ON s2.ID_LEVEL = s1.ID_LEVEL
           AND s2.ID_SECTION < s1.ID_SECTION
         WHERE s1.ID_SECTION = p_id_section
         ORDER BY s2.ID_SECTION DESC
         FETCH FIRST 1 ROWS ONLY;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          v_prev_section := NULL;
      END;

      INSERT INTO USER_SECTION_PROGRESS(ID_USER, ID_SECTION, STATUS, LAST_SCORE, ATTEMPTS)
      VALUES (p_id_user, p_id_section,
              CASE WHEN v_prev_section IS NULL THEN 'EN PROGRESO' ELSE 'BLOQUEADO' END,
              NULL, 0);
    END IF;
  END;

  FUNCTION CAN_START_PRACTICE(p_id_user IN NUMBER, p_id_section IN NUMBER)
    RETURN CHAR IS
    v_status VARCHAR2(12);
  BEGIN
    ENSURE_ROW(p_id_user, p_id_section);
    SELECT STATUS INTO v_status
      FROM USER_SECTION_PROGRESS
     WHERE ID_USER = p_id_user AND ID_SECTION = p_id_section;
    RETURN CASE WHEN v_status IN ('EN PROGRESO','APROBADO') THEN 'S' ELSE 'N' END;
  END;

  FUNCTION START_ATTEMPT(p_id_user IN NUMBER, p_id_section IN NUMBER)
    RETURN NUMBER IS
    v_id  PRACTICE_ATTEMPT.ID_ATTEMPT%TYPE;
    v_can CHAR(1);
  BEGIN
    v_can := CAN_START_PRACTICE(p_id_user, p_id_section);
    IF v_can = 'N' THEN
      RAISE_APPLICATION_ERROR(-20020, 'SECCION BLOQUEADA');
    END IF;

    PKG_ACCOUNT.REFRESH_LIVES(p_id_user);
    PKG_ACCOUNT.SPEND_LIFE(p_id_user, 1);

    INSERT INTO PRACTICE_ATTEMPT (ID_USER, ID_SECTION, SCORE, STATUS, STARTED_AT)
    VALUES (p_id_user, p_id_section, NULL, 'IN_PROGRESS', SYSTIMESTAMP)
    RETURNING ID_ATTEMPT INTO v_id;

    RETURN v_id;
  END;

  PROCEDURE FINISH_ATTEMPT(
    p_id_user    IN NUMBER,
    p_id_section IN NUMBER,
    p_score      IN NUMBER
  ) IS
    v_id_attempt PRACTICE_ATTEMPT.ID_ATTEMPT%TYPE;
    v_next_section NUMBER;
  BEGIN
    IF p_score < 0 OR p_score > 5 THEN
      RAISE_APPLICATION_ERROR(-20021, 'Score debe estar entre 0 y 5');
    END IF;

    BEGIN
      SELECT id_attempt
        INTO v_id_attempt
        FROM (
          SELECT id_attempt
            FROM PRACTICE_ATTEMPT
           WHERE id_user = p_id_user
             AND id_section = p_id_section
             AND status = 'IN_PROGRESS'
           ORDER BY started_at DESC
        )
       WHERE ROWNUM = 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        INSERT INTO PRACTICE_ATTEMPT (ID_USER, ID_SECTION, SCORE, STATUS, STARTED_AT)
        VALUES (p_id_user, p_id_section, NULL, 'IN_PROGRESS', SYSTIMESTAMP)
        RETURNING ID_ATTEMPT INTO v_id_attempt;
    END;

    UPDATE PRACTICE_ATTEMPT
       SET score       = p_score,
           status      = 'FINISHED',
           finished_at = SYSTIMESTAMP,
           attempted_at = SYSDATE
     WHERE id_attempt = v_id_attempt;

    ENSURE_ROW(p_id_user, p_id_section);

    UPDATE USER_SECTION_PROGRESS
       SET last_score   = p_score,
           attempts     = attempts + 1,
           status       = CASE WHEN p_score >= g_pass_threshold THEN 'APROBADO' ELSE status END,
           completed_at = CASE WHEN p_score >= g_pass_threshold THEN NVL(completed_at, SYSDATE) ELSE completed_at END
     WHERE id_user = p_id_user
       AND id_section = p_id_section;

    IF p_score >= g_pass_threshold THEN
      BEGIN
        SELECT s2.ID_SECTION
          INTO v_next_section
          FROM SECTION s1
          JOIN SECTION s2
            ON s2.ID_LEVEL = s1.ID_LEVEL
           AND s2.ID_SECTION > s1.ID_SECTION
         WHERE s1.ID_SECTION = p_id_section
         ORDER BY s2.ID_SECTION
         FETCH FIRST 1 ROWS ONLY;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          v_next_section := NULL;
      END;

      IF v_next_section IS NOT NULL THEN
        ENSURE_ROW(p_id_user, v_next_section);
        UPDATE USER_SECTION_PROGRESS
           SET STATUS = CASE WHEN STATUS = 'BLOQUEADO' THEN 'EN PROGRESO' ELSE STATUS END
         WHERE ID_USER = p_id_user
           AND ID_SECTION = v_next_section;
      END IF;
    END IF;
  END;

  FUNCTION SECTION_PROGRESS_PCT(
    p_id_user    IN NUMBER,
    p_id_section IN NUMBER
  ) RETURN NUMBER IS
    v_total        NUMBER;
    v_pos          NUMBER;
    v_tm           NUMBER;
    v_page_current NUMBER;
  BEGIN
    BEGIN
      SELECT ID_THEORY_MODULE INTO v_tm
        FROM THEORY_MODULE
       WHERE ID_SECTION = p_id_section;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN 0;
    END;

    SELECT COUNT(*) INTO v_total
      FROM PAGE
     WHERE ID_THEORY_MODULE = v_tm;

    IF v_total = 0 THEN
      RETURN 0;
    END IF;

    BEGIN
      SELECT ID_PAGE INTO v_page_current
        FROM USER_ACCOUNT
       WHERE ID_USER = p_id_user;
      IF v_page_current IS NULL THEN
        RETURN 0;
      END IF;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN 0;
    END;

    DECLARE
      v_page_section NUMBER;
    BEGIN
      SELECT tm.ID_SECTION INTO v_page_section
        FROM PAGE p
        JOIN THEORY_MODULE tm ON tm.ID_THEORY_MODULE = p.ID_THEORY_MODULE
       WHERE p.ID_PAGE = v_page_current;
      IF v_page_section != p_id_section THEN
        RETURN 0;
      END IF;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN 0;
    END;

    SELECT COUNT(*) INTO v_pos
      FROM PAGE p
     WHERE p.ID_THEORY_MODULE = v_tm
       AND p.PAGE_ORDER <= (
         SELECT p2.PAGE_ORDER
           FROM PAGE p2
          WHERE p2.ID_PAGE = v_page_current
       );
    RETURN ROUND((v_pos / v_total) * 100, 2);
  EXCEPTION
    WHEN OTHERS THEN
      RETURN 0;
  END;
END PKG_PROGRESS;
/

CREATE OR REPLACE PACKAGE BODY PKG_USER_REGISTRATION AS

  g_provider CONSTANT VARCHAR2(40) := 'GOOGLE';

  PROCEDURE INITIALIZE_PROGRESS(p_id_user IN NUMBER) IS
    v_first_section SECTION.ID_SECTION%TYPE;
  BEGIN
    BEGIN
      SELECT s.ID_SECTION
        INTO v_first_section
        FROM SECTION s
        JOIN LEVELS l ON l.ID_LEVEL = s.ID_LEVEL
       ORDER BY l.ID_LEVEL, s.ID_SECTION
       FETCH FIRST 1 ROWS ONLY;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN;
    END;

    IF v_first_section IS NOT NULL THEN
      PKG_PROGRESS.ENSURE_ROW(
        p_id_user    => p_id_user,
        p_id_section => v_first_section
      );
    END IF;
  END INITIALIZE_PROGRESS;

  PROCEDURE HANDLE_GOOGLE_LOGIN(
    p_email       IN VARCHAR2,
    p_google_name IN VARCHAR2,
    p_google_id   IN VARCHAR2,
    p_id_user     OUT NUMBER
  ) IS
    v_id_user      APP_USER.ID_USER%TYPE;
    v_username     APP_USER.USERNAME%TYPE;
    v_is_new_user  BOOLEAN := FALSE;
  BEGIN
    IF p_email IS NULL OR p_google_id IS NULL THEN
      RAISE_APPLICATION_ERROR(-20100, 'Email y Google ID son obligatorios');
    END IF;

    BEGIN
      SELECT ea.ID_USER
        INTO v_id_user
        FROM EXTERNAL_AUTH ea
       WHERE ea.PROVIDER = g_provider
         AND ea.PROVIDER_ID = p_google_id;
      p_id_user := v_id_user;
      RETURN;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;

    BEGIN
      SELECT ID_USER
        INTO v_id_user
        FROM APP_USER
       WHERE UPPER(EMAIL) = UPPER(p_email);
      p_id_user := v_id_user;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_is_new_user := TRUE;
    END;

    IF v_is_new_user THEN
      v_username := SUBSTR(TRIM(p_google_name), 1, 80);
      IF v_username IS NULL OR LENGTH(v_username) = 0 THEN
        v_username := SUBSTR(p_email, 1, INSTR(p_email, '@') - 1);
      END IF;

      INSERT INTO APP_USER (EMAIL, USERNAME, CREATED_AT, UPDATED_AT)
      VALUES (LOWER(p_email), v_username, SYSDATE, SYSDATE)
      RETURNING ID_USER INTO v_id_user;
      p_id_user := v_id_user;
    END IF;

    PKG_ACCOUNT.CREATE_DEFAULT_ACCOUNT(p_id_user => p_id_user);
    INITIALIZE_PROGRESS(p_id_user => p_id_user);
    PKG_AUTH.SYNC_EXTERNAL(
      p_id_user     => p_id_user,
      p_provider    => g_provider,
      p_provider_id => p_google_id
    );

  EXCEPTION
    WHEN OTHERS THEN
      RAISE;
  END HANDLE_GOOGLE_LOGIN;

END PKG_USER_REGISTRATION;
/