-- TRIGGERS

CREATE OR REPLACE TRIGGER TRG_APP_USER_TOUCH
BEFORE UPDATE ON APP_USER
FOR EACH ROW
BEGIN
  :NEW.UPDATED_AT := SYSDATE;
END;
/

CREATE OR REPLACE TRIGGER TRG_SUBSCRIPTION_DATES
BEFORE INSERT OR UPDATE ON SUBSCRIPTION
FOR EACH ROW
BEGIN
  IF :NEW.END_DATE <= :NEW.START_DATE THEN
    RAISE_APPLICATION_ERROR(-20001, 'END_DATE DEBE SER MAYOR A START_DATE');
  END IF;
END;
/

CREATE OR REPLACE TRIGGER TRG_SECTION_CREATE_MODULES
AFTER INSERT ON SECTION
FOR EACH ROW
BEGIN
  -- Crea modulo de teoría de manera automatica
  INSERT INTO THEORY_MODULE (ID_SECTION)
  VALUES (:NEW.ID_SECTION);

  -- Crear modulo de práctica de manera automatica
  INSERT INTO PRACTICE_MODULE (ID_SECTION)
  VALUES (:NEW.ID_SECTION);
END;
/


-- VISTAS

CREATE OR REPLACE VIEW V_ACTIVE_SUBSCRIPTION AS
SELECT s.ID_USER, s.ID_SUBSCRIPTION, s.START_DATE, s.END_DATE, s.STATUS
FROM SUBSCRIPTION s
WHERE s.STATUS = 'ACTIVO'
  AND TRUNC(SYSDATE) BETWEEN TRUNC(s.START_DATE) AND TRUNC(s.END_DATE);
/

CREATE OR REPLACE VIEW V_CONTENT_BROWSE AS
SELECT
  lv.ID_LEVEL, lv.NAME AS LEVEL_NAME,
  se.ID_SECTION, se.NAME AS SECTION_NAME, se.DESCRIPTION,
  tm.ID_THEORY_MODULE,
  pg.ID_PAGE, pg.PAGE_ORDER, pg.NAME AS PAGE_NAME
FROM LEVELS lv
JOIN SECTION se        ON se.ID_LEVEL = lv.ID_LEVEL
LEFT JOIN THEORY_MODULE tm ON tm.ID_SECTION = se.ID_SECTION
LEFT JOIN PAGE pg          ON pg.ID_THEORY_MODULE = tm.ID_THEORY_MODULE;
/

CREATE OR REPLACE VIEW V_USER_ACCOUNT_INFO AS
SELECT
  u.ID_USER, u.EMAIL, u.USERNAME, a.LIVES, a.ID_PAGE
FROM APP_USER u
LEFT JOIN USER_ACCOUNT a ON a.ID_USER = u.ID_USER;
/

CREATE OR REPLACE VIEW V_USER_DASHBOARD AS
WITH
SECTIONS_TOTAL AS (
  SELECT COUNT(*) AS CNT FROM SECTION
),
APPROVED AS (
  SELECT usp.id_user,
         MAX(s.id_level) AS highest_level_id
  FROM USER_SECTION_PROGRESS usp
  JOIN SECTION s ON s.id_section = usp.id_section
  WHERE usp.status = 'APROBADO'
  GROUP BY usp.id_user
),
AVG_SCORE AS (
  SELECT pa.id_user,
         AVG(pa.score) AS avg_score
  FROM PRACTICE_ATTEMPT pa
  WHERE pa.status = 'FINISHED'
     OR pa.score IS NOT NULL
  GROUP BY pa.id_user
),
COMPLETED AS (
  SELECT id_user,
         COUNT(*) AS sections_completed
  FROM USER_SECTION_PROGRESS
  WHERE status = 'APROBADO'
  GROUP BY id_user
),
LAST_PAGE AS (
  SELECT ua.id_user,
         ua.id_page,
         p.name       AS last_page_name,
         p.page_order AS last_page_order
  FROM USER_ACCOUNT ua
  LEFT JOIN PAGE p ON p.id_page = ua.id_page
),
SUB_ACTIVE AS (
  SELECT id_user,
         'Y' AS is_premium,
         plan_name,
         expires_at
  FROM (
    SELECT sb.id_user,
           sp.name     AS plan_name,
           sb.end_date AS expires_at,
           ROW_NUMBER() OVER (
             PARTITION BY sb.id_user ORDER BY sb.end_date DESC
           ) AS rn
    FROM SUBSCRIPTION sb
    JOIN SUBSCRIPTION_PLAN sp ON sp.id_plan = sb.id_plan
    WHERE sb.status = 'ACTIVO'
      AND TRUNC(SYSDATE) BETWEEN TRUNC(sb.start_date) AND TRUNC(sb.end_date)
  )
  WHERE rn = 1
)
SELECT
  u.id_user,
  u.username, 
  a.highest_level_id,
  (SELECT l.name FROM LEVELS l WHERE l.id_level = a.highest_level_id)
    AS highest_level_name,
  ROUND(NVL(avgS.avg_score, 0), 2)        AS avg_score_overall,
  NVL(c.sections_completed, 0)            AS sections_completed,
  st.cnt                                   AS sections_total,
  lp.id_page                               AS last_page_id,
  lp.last_page_name,
  lp.last_page_order,
  CASE WHEN sa.is_premium = 'Y' THEN 1 ELSE 0 END AS is_premium,
  sa.plan_name,
  sa.expires_at
FROM APP_USER u
LEFT JOIN APPROVED   a    ON a.id_user    = u.id_user
LEFT JOIN AVG_SCORE  avgS ON avgS.id_user = u.id_user
LEFT JOIN COMPLETED  c    ON c.id_user    = u.id_user
CROSS JOIN SECTIONS_TOTAL st
LEFT JOIN LAST_PAGE  lp   ON lp.id_user   = u.id_user
LEFT JOIN SUB_ACTIVE sa   ON sa.id_user   = u.id_user;
/

CREATE OR REPLACE VIEW V_USER_SECTION_STATS AS
SELECT
  usp.id_user,
  s.id_level,
  l.name       AS level_name,
  s.id_section,
  s.name       AS section_name,
  usp.attempts,
  usp.last_score,
  NVL(ms.max_score, usp.last_score) AS max_score
FROM USER_SECTION_PROGRESS usp
JOIN SECTION s   ON s.id_section = usp.id_section
JOIN LEVELS  l   ON l.id_level   = s.id_level
LEFT JOIN (
  SELECT id_user, id_section, MAX(score) AS max_score
  FROM PRACTICE_ATTEMPT
  WHERE (status = 'FINISHED' OR score IS NOT NULL)
  GROUP BY id_user, id_section
) ms ON ms.id_user = usp.id_user AND ms.id_section = usp.id_section;
/