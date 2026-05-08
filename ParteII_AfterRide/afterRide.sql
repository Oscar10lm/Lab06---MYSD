-- ====================================================================
-- Parte A: Construcción [En lab05.doc afterRide.sql]
-- ====================================================================

-- 1. Consulten la información que actualmente está en la tabla. ¿Cuántos datos tiene?
SELECT * FROM mbda.data;

-- 2. Inclúyanse como participantes (usen sus correos). Capturen una pantalla de esta información en DATA.
INSERT INTO mbda.DATA (NUMERO, PAIS, CORREO, NOMBRE, APELLIDO, NACIMIENTO, CATEGORIA)
VALUES ('1053442983', 'Colombia', 'oscar.lasso-m@mail.escuelaing.edu.co', 'Oscar', 'Lasso', '2005-08-10', '5');

COMMIT;

-- 3. Traten de modificarse o borrarse. ¿qué pasa?
UPDATE mbda.DATA SET APELLIDO = 'Martinez' WHERE NUMERO = '1053442983';
DELETE FROM mbda.DATA WHERE NUMERO = '1021312556';

-- 4. Escriban la instrucción necesaria para otorgar los permisos que actualmente tiene esa tabla. ¿quién la escribió?
SELECT GRANTOR, GRANTEE, PRIVILEGE, GRANTABLE
FROM ALL_TAB_PRIVS
WHERE TABLE_NAME = 'DATA' AND OWNER = 'MBDA';

GRANT SELECT, INSERT, UPDATE, DELETE ON mbda.DATA TO "oscar.lasso-m";

-- 5. Escriban las instrucciones necesarias para importar los datos de esa tabla a su base de datos como participantes. Los datos deben insertados en las tablas de su base de datos, considerando: Todos los participantes se identifican por la cédula de ciudadanía. Las categorías mayores a 5 se convierten en categoría 5 y las menores a 1 en categoría 1.
INSERT INTO PARTICIPANTES (NUMERO, PAIS, CORREO, NOMBRE, APELLIDO, NACIMIENTO, CATEGORIA)
SELECT 
    NUMERO,
    PAIS,
    CORREO,
    NOMBRE,
    APELLIDO,
    NACIMIENTO,
    CASE 
        WHEN CATEGORIA > 5 THEN 5
        WHEN CATEGORIA < 1 THEN 1
        ELSE CATEGORIA
    END
FROM MBDA.DATA;

-- ====================================================================
-- PARTE II B. Modelo fisico componentes
-- ====================================================================

-- ================== CONCEPTO AZUL ==================
-- CRUDE
CREATE OR REPLACE PACKAGE PC_REGISTRO IS
    PROCEDURE AD_REGISTRO(n_numero IN NUMBER, n_fecha IN DATE, n_tiempo IN NUMBER, n_posicion IN NUMBER, n_ciclista IN NUMBER, n_nombre_version IN VARCHAR2, n_nombre_segmento IN VARCHAR2);
    PROCEDURE UP_REGISTRO(n_numero IN NUMBER, n_nuevo_tiempo IN NUMBER);
    PROCEDURE DE_REGISTRO(n_numero IN NUMBER);
    FUNCTION CO_TOP_5_SEGMENTOS RETURN SYS_REFCURSOR;
END PC_REGISTRO;
/

-- CRUDI
CREATE OR REPLACE PACKAGE BODY PC_REGISTRO IS
    PROCEDURE AD_REGISTRO(n_numero IN NUMBER, n_fecha IN DATE, n_tiempo IN NUMBER, n_posicion IN NUMBER, n_ciclista IN NUMBER, n_nombre_version IN VARCHAR2, n_nombre_segmento IN VARCHAR2) IS
    BEGIN
        INSERT INTO Registro (numero, fecha, tiempo, posicion, ciclista_id, nombre_version, nombre_segmento)
        VALUES (n_numero, n_fecha, n_tiempo, n_posicion, n_ciclista, n_nombre_version, n_nombre_segmento);
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN ROLLBACK; RAISE;
    END;

    PROCEDURE UP_REGISTRO(n_numero IN NUMBER, n_nuevo_tiempo IN NUMBER) IS
    BEGIN
        UPDATE Registro SET tiempo = n_nuevo_tiempo WHERE numero = n_numero;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN ROLLBACK; RAISE;
    END;

    PROCEDURE DE_REGISTRO(n_numero IN NUMBER) IS
    BEGIN
        DELETE FROM Registro WHERE numero = n_numero;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN ROLLBACK; RAISE;
    END;

    FUNCTION CO_TOP_5_SEGMENTOS RETURN SYS_REFCURSOR IS
        v_cur SYS_REFCURSOR;
    BEGIN
        OPEN v_cur FOR 
            SELECT nombre_segmento, MIN(tiempo) as mejor_tiempo 
            FROM Registro 
            GROUP BY nombre_segmento 
            ORDER BY mejor_tiempo ASC 
            FETCH FIRST 5 ROWS ONLY;
        RETURN v_cur;
    END;
END PC_REGISTRO;
/

-- ================== CONCEPTO ROJO ==================
-- CRUDE
CREATE OR REPLACE PACKAGE PC_EVALUACION IS
    PROCEDURE AD_EVALUACION(n_id_ev IN NUMBER, n_fecha IN DATE, n_puntuacion IN NUMBER, n_estado IN VARCHAR2, n_p_id IN NUMBER, n_codigo_carrera IN VARCHAR2, n_id_encuesta IN NUMBER);
    PROCEDURE UP_EVALUACION(n_id_ev IN NUMBER, n_nueva_puntuacion IN NUMBER);
    PROCEDURE DE_EVALUACION(n_id_ev IN NUMBER);
    PROCEDURE AD_COMENTARIO(n_id_com IN NUMBER, n_contenido IN VARCHAR2, n_id_evaluacion IN NUMBER);
END PC_EVALUACION;
/

-- CRUDI
CREATE OR REPLACE PACKAGE BODY PC_EVALUACION IS
    PROCEDURE AD_EVALUACION(n_id_ev IN NUMBER, n_fecha IN DATE, n_puntuacion IN NUMBER, n_estado IN VARCHAR2, n_p_id IN NUMBER, n_codigo_carrera IN VARCHAR2, n_id_encuesta IN NUMBER) IS
    BEGIN
        INSERT INTO Evaluacion (id_ev, fecha, puntuacion, estado, p_id, codigo_carrera, id_encuesta)
        VALUES (n_id_ev, n_fecha, n_puntuacion, n_estado, n_p_id, n_codigo_carrera, n_id_encuesta);
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN ROLLBACK; RAISE;
    END;

    PROCEDURE UP_EVALUACION(n_id_ev IN NUMBER, n_nueva_puntuacion IN NUMBER) IS
    BEGIN
        UPDATE Evaluacion SET puntuacion = n_nueva_puntuacion WHERE id_ev = n_id_ev;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN ROLLBACK; RAISE;
    END;

    PROCEDURE DE_EVALUACION(n_id_ev IN NUMBER) IS
    BEGIN
        DELETE FROM Evaluacion WHERE id_ev = n_id_ev;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN ROLLBACK; RAISE;
    END;

    PROCEDURE AD_COMENTARIO(n_id_com IN NUMBER, n_contenido IN VARCHAR2, n_id_evaluacion IN NUMBER) IS
    BEGIN
        INSERT INTO Comentario (id_com, contenido, id_evaluacion)
        VALUES (n_id_com, n_contenido, n_id_evaluacion);
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN ROLLBACK; RAISE;
    END;
END PC_EVALUACION;
/

-- ================== CONCEPTO AMARILLO ==================
-- CRUDE
CREATE OR REPLACE PACKAGE PC_CARRERA IS
    PROCEDURE AD_CARRERA(n_codigo_carrera IN VARCHAR2, n_nombre IN VARCHAR2, n_pais IN VARCHAR2, n_categoria IN NUMBER, n_periodicidad IN VARCHAR2);
    PROCEDURE AD_PUNTO(n_orden IN NUMBER, n_nombre IN VARCHAR2, n_tipo IN VARCHAR2, n_distancia IN NUMBER, n_codigo_carrera IN VARCHAR2, n_nombre_version IN VARCHAR2);
    FUNCTION CO_PUNTOS_CARRERA(n_codigo_carrera IN VARCHAR2) RETURN SYS_REFCURSOR;
END PC_CARRERA;
/

-- CRUDI
CREATE OR REPLACE PACKAGE BODY PC_CARRERA IS
    PROCEDURE AD_CARRERA(n_codigo_carrera IN VARCHAR2, n_nombre IN VARCHAR2, n_pais IN VARCHAR2, n_categoria IN NUMBER, n_periodicidad IN VARCHAR2) IS
    BEGIN
        INSERT INTO Carrera (codigo_carrera, nombre, pais, categoria, periodicidad)
        VALUES (n_codigo_carrera, n_nombre, n_pais, n_categoria, n_periodicidad);
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN ROLLBACK; RAISE_APPLICATION_ERROR(-20010, 'Error al insertar carrera: ' || SQLERRM);
    END;

    PROCEDURE AD_PUNTO(n_orden IN NUMBER, n_nombre IN VARCHAR2, n_tipo IN VARCHAR2, n_distancia IN NUMBER, n_codigo_carrera IN VARCHAR2, n_nombre_version IN VARCHAR2) IS
    BEGIN
        INSERT INTO Punto (orden, nombre, tipo, distancia, codigo_carrera, nombre_version)
        VALUES (n_orden, n_nombre, n_tipo, n_distancia, n_codigo_carrera, n_nombre_version);
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN ROLLBACK; RAISE_APPLICATION_ERROR(-20011, 'Error al insertar punto: ' || SQLERRM);
    END;

    FUNCTION CO_PUNTOS_CARRERA(n_codigo_carrera IN VARCHAR2) RETURN SYS_REFCURSOR IS
        v_cursor SYS_REFCURSOR;
    BEGIN
        OPEN v_cursor FOR
            SELECT orden, nombre, tipo, distancia 
            FROM Punto 
            WHERE codigo_carrera = n_codigo_carrera
            ORDER BY orden ASC;
        RETURN v_cursor;
    END;
END PC_CARRERA;
/

-- ================== CONCEPTO MORADO ==================
-- CRUDE
CREATE OR REPLACE PACKAGE PC_PARTICIPANTE IS
    PROCEDURE AD_PARTICIPANTE(n_id IN NUMBER, n_tipo_id IN VARCHAR2, n_numero_id IN NUMBER, n_pais IN VARCHAR2, n_correo IN VARCHAR2);
    PROCEDURE AD_PERSONA(n_id IN NUMBER, n_nombres IN VARCHAR2);
    PROCEDURE AD_CICLISTA(n_id IN NUMBER, n_nacimiento IN DATE, n_categoria IN NUMBER);
    FUNCTION CO_DATOS_CONTACTO(n_id IN NUMBER) RETURN SYS_REFCURSOR;
END PC_PARTICIPANTE;
/

-- CRUDI
CREATE OR REPLACE PACKAGE BODY PC_PARTICIPANTE IS
    PROCEDURE AD_PARTICIPANTE(n_id IN NUMBER, n_tipo_id IN VARCHAR2, n_numero_id IN NUMBER, n_pais IN VARCHAR2, n_correo IN VARCHAR2) IS
    BEGIN
        INSERT INTO Participante (id_participante, tipo_id, numero_id, pais, correo)
        VALUES (n_id, n_tipo_id, n_numero_id, n_pais, n_correo);
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN ROLLBACK; RAISE_APPLICATION_ERROR(-20019, 'Error al insertar participante: ' || SQLERRM);
    END;

    PROCEDURE AD_PERSONA(n_id IN NUMBER, n_nombres IN VARCHAR2) IS
    BEGIN
        INSERT INTO Persona (persona_id, nombres)
        VALUES (n_id, n_nombres);
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN ROLLBACK; RAISE_APPLICATION_ERROR(-20020, 'Error al insertar persona: ' || SQLERRM);
    END;

    PROCEDURE AD_CICLISTA(n_id IN NUMBER, n_nacimiento IN DATE, n_categoria IN NUMBER) IS
    BEGIN
        INSERT INTO Ciclista (ciclista_id, nacimiento, categoria)
        VALUES (n_id, n_nacimiento, n_categoria);
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN ROLLBACK; RAISE_APPLICATION_ERROR(-20021, 'Error al insertar ciclista: ' || SQLERRM);
    END;

    FUNCTION CO_DATOS_CONTACTO(n_id IN NUMBER) RETURN SYS_REFCURSOR IS
        v_cursor SYS_REFCURSOR;
    BEGIN
        OPEN v_cursor FOR
            SELECT part.correo, per.nombres, c.categoria
            FROM Participante part
            LEFT JOIN Persona per ON part.id_participante = per.persona_id
            LEFT JOIN Ciclista c ON part.id_participante = c.ciclista_id
            WHERE part.id_participante = n_id;
        RETURN v_cursor;
    END;
END PC_PARTICIPANTE;
/

-- ================== XCRUDE ==================
/*
DROP PACKAGE PC_REGISTRO;
DROP PACKAGE PC_EVALUACION;
DROP PACKAGE PC_CARRERA;
DROP PACKAGE PC_PARTICIPANTE;
*/

-- ====================================================================
-- 2. Prueben el paquete con los casos más significativos
-- ====================================================================

-- ================== CRUDOK: 5 casos de éxito ==================

-- 1. Registrar un nuevo participante exitosamente
EXEC PC_PARTICIPANTE.AD_PARTICIPANTE(1001, 'CC', 10101010, 'Colombia', 'ciclista1@mail.com');

-- 2. Registrar al participante como ciclista con una categoría válida entre 1 y 5
EXEC PC_PARTICIPANTE.AD_CICLISTA(1001, TO_DATE('1995-05-15', 'YYYY-MM-DD'), 3);

-- 3. Registrar una nueva carrera con categoría y periodicidad válidas
EXEC PC_CARRERA.AD_CARRERA('C99', 'Tour Prueba', 'Colombia', 1, 'Anual');

-- 4. Modificar el tiempo de un registro para probar la actualización de datos
-- Asume que el registro con numero 1 existe según las tuplas iniciales del lab.
EXEC PC_REGISTRO.UP_REGISTRO(1, 450);

-- 5. Eliminar una evaluación específica de la base de datos
-- Asume que la evaluación con id 10 existe según las tuplas iniciales del lab.
EXEC PC_EVALUACION.DE_EVALUACION(10);


-- ================== CRUDNoOK: 3 casos de fracaso ==================

-- 1. Fallo por Restricción de Check debido a una categoría inválida para Ciclista mayor a 5
-- La tabla Ciclista restringe los valores de categoría entre 1 y 5. El valor 6 generará el error ORA-02290.
EXEC PC_PARTICIPANTE.AD_CICLISTA(1002, TO_DATE('1990-01-01', 'YYYY-MM-DD'), 6);

-- 2. Fallo por Restricción de Check debido a un tiempo negativo en Registro
-- La tabla Registro restringe el tiempo para que sea mayor a cero. El valor -50 generará el error ORA-02290.
EXEC PC_REGISTRO.AD_REGISTRO(999, SYSDATE, -50, 1, 1001, 'V01', 'SEG1');

-- 3. Fallo por Restricción Única debido a un participante duplicado
-- La tabla Participante tiene una restricción única para el tipo y número de documento. 
-- Como ya insertamos la cédula 10101010 en el primer caso exitoso, intentarlo de nuevo fallará por el error ORA-00001.
EXEC PC_PARTICIPANTE.AD_PARTICIPANTE(1003, 'CC', 10101010, 'Peru', 'duplicado@mail.com');

-- ====================================================================
-- PARTE III. DESARROLLANDO: FÍSICO DE ACTORES
-- ====================================================================

-- 1. Diseñen e implementen los paquetes que ofrezcan las operaciones válidas del caso de uso Registrar registro para cada uno de los siguientes actores.

-- ================== ActoresE (Especificación) ==================

-- Paquete para el Actor Participante
CREATE OR REPLACE PACKAGE PA_PARTICIPANTE IS
    -- Un participante puede registrar su propio desempeño usando los parámetros de la carrera
    PROCEDURE REGISTRAR_TIEMPO(n_numero IN NUMBER, n_tiempo IN NUMBER, n_posicion IN NUMBER, n_ciclista_id IN NUMBER, n_nombre_version IN VARCHAR2, n_nombre_segmento IN VARCHAR2);
    
    -- Un participante puede consultar sus propios datos de contacto mediante su ID de sesión
    FUNCTION CONSULTAR_MIS_DATOS(n_ciclista_id IN NUMBER) RETURN SYS_REFCURSOR;
END PA_PARTICIPANTE;
/

-- Paquete para el Actor Persona, el cual es el actor más general
CREATE OR REPLACE PACKAGE PA_PERSONA IS
    -- Una persona puede ver los resultados generales del Top 5
    FUNCTION VER_MEJORES_TIEMPOS RETURN SYS_REFCURSOR;
    
    -- Una persona puede ver la información de las carreras disponibles
    FUNCTION CONSULTAR_CARRERAS RETURN SYS_REFCURSOR;
END PA_PERSONA;
/

-- ================== ActoresI (Implementación) ==================

-- Implementación Participante
CREATE OR REPLACE PACKAGE BODY PA_PARTICIPANTE IS
    PROCEDURE REGISTRAR_TIEMPO(n_numero IN NUMBER, n_tiempo IN NUMBER, n_posicion IN NUMBER, n_ciclista_id IN NUMBER, n_nombre_version IN VARCHAR2, n_nombre_segmento IN VARCHAR2) IS
    BEGIN
        -- Se delega la responsabilidad al paquete CRUD componente correspondiente PC_REGISTRO
        PC_REGISTRO.AD_REGISTRO(n_numero, SYSDATE, n_tiempo, n_posicion, n_ciclista_id, n_nombre_version, n_nombre_segmento); 
    END;

    FUNCTION CONSULTAR_MIS_DATOS(n_ciclista_id IN NUMBER) RETURN SYS_REFCURSOR IS
    BEGIN
        -- Se delega la consulta al paquete de componente correspondiente PC_PARTICIPANTE
        RETURN PC_PARTICIPANTE.CO_DATOS_CONTACTO(n_ciclista_id);
    END;
END PA_PARTICIPANTE;
/

-- Implementación Persona
CREATE OR REPLACE PACKAGE BODY PA_PERSONA IS
    FUNCTION VER_MEJORES_TIEMPOS RETURN SYS_REFCURSOR IS
    BEGIN
        -- Llama a la función del paquete de Registro correspondiente al Componente Azul
        RETURN PC_REGISTRO.CO_TOP_5_SEGMENTOS;
    END;

    FUNCTION CONSULTAR_CARRERAS RETURN SYS_REFCURSOR IS
        v_cursor SYS_REFCURSOR;
    BEGIN
        -- Al no haber un CRUD específico para listar carreras de vista pública, se puede hacer directo o llamar a un PC_CARRERA
        OPEN v_cursor FOR 
            SELECT codigo_carrera, nombre, pais, periodicidad 
            FROM Carrera;
        RETURN v_cursor;
    END;
END PA_PERSONA;
/

-- ====================================================================
-- 2. Creen los dos roles anteriores y otorguen los permisos correspondientes a cada uno de esos.
-- Seguridad (Autorizaciones)
-- ====================================================================

-- 1. Creación de los roles de base de datos
CREATE ROLE R_PARTICIPANTE;
CREATE ROLE R_PERSONA;

-- 2. Otorgar permisos de ejecución sobre los paquetes correspondientes a los actores

-- El rol del participante solamente tiene autorización para usar el paquete PA_PARTICIPANTE
GRANT EXECUTE ON PA_PARTICIPANTE TO R_PARTICIPANTE;

-- El rol de persona solamente tiene autorización para usar el paquete PA_PERSONA
GRANT EXECUTE ON PA_PERSONA TO R_PERSONA;

-- ====================================================================
-- 3. Asignen el primer rol al miembro del equipo que no creo la base de datos y el segundo rol a un compañero del curso (no del equipo).
-- ====================================================================

-- Asignar el primer rol al miembro del equipo que no creó la base de datos
GRANT R_PARTICIPANTE TO bd1000100876;

-- Asignar el segundo rol a un compañero del curso que no es del equipo
GRANT R_PERSONA TO bd1000105520;

-- ====================================================================
-- 4. Prueben el esquema de seguridad con los casos más significativos
-- ====================================================================

-- ================== SeguridadOK: 5 casos de éxito ==================

-- 1. El rol Persona consulta la lista de carreras disponibles exitosamente
VAR rc_carreras REFCURSOR;
EXEC :rc_carreras := PA_PERSONA.CONSULTAR_CARRERAS();
PRINT rc_carreras;

-- 2. El rol Persona visualiza los mejores tiempos de los segmentos sin problemas
VAR rc_tiempos REFCURSOR;
EXEC :rc_tiempos := PA_PERSONA.VER_MEJORES_TIEMPOS();
PRINT rc_tiempos;

-- 3. El rol Participante registra el tiempo de un nuevo segmento de forma exitosa
EXEC PA_PARTICIPANTE.REGISTRAR_TIEMPO(2, 500, 1, 1001, 'V01', 'SEG2');

-- 4. El rol Participante registra su desempeño en otro segmento adicional
EXEC PA_PARTICIPANTE.REGISTRAR_TIEMPO(3, 480, 2, 1001, 'V01', 'SEG3');

-- 5. El rol Participante consulta sus propios datos de contacto correctamente
VAR rc_mis_datos REFCURSOR;
EXEC :rc_mis_datos := PA_PARTICIPANTE.CONSULTAR_MIS_DATOS(1001);
PRINT rc_mis_datos;

-- ================== SeguridadNoOK: 3 casos de fracaso ==================

-- 1. Fallo al intentar usar un paquete sin autorización cruzada
-- Si el usuario con rol Participante intenta usar un paquete de Persona, la base de datos denegará el acceso.
VAR rc_error REFCURSOR;
EXEC :rc_error := PA_PERSONA.VER_MEJORES_TIEMPOS();

-- 2. Fallo de privacidad al intentar invocar el registro de otro actor
-- Si el usuario con rol Persona intenta registrar un tiempo en el paquete de Participante, el sistema lo bloqueará.
EXEC PA_PARTICIPANTE.REGISTRAR_TIEMPO(4, 300, 1, 1002, 'V01', 'SEG1');

-- 3. Fallo por violación del encapsulamiento al intentar insertar datos directamente
-- Ninguno de los usuarios finales tiene permisos de inserción directa sobre la tabla física, por lo que esto generará error.
INSERT INTO Registro (numero, fecha, tiempo, posicion, ciclista_id, nombre_version, nombre_segmento) 
VALUES (99, SYSDATE, 100, 1, 1001, 'V01', 'SEG1');


-- ====================================================================
-- PARTE IV. PROBANDO: Prueba de Aceptación
-- ====================================================================

-- Preparación del entorno de consola
SET SERVEROUTPUT ON;
VAR historia_cursor REFCURSOR;

PROMPT ==========================================================
PROMPT HISTORIA DE USUARIO: Participacion en El Gran Fondo
PROMPT ==========================================================

PROMPT Paso 1: Una persona interesada en competir consulta las carreras disponibles en el sistema.
EXEC :historia_cursor := PA_PERSONA.CONSULTAR_CARRERAS();
PRINT historia_cursor;

PROMPT Paso 2: El ciclista Carlos (ID 1001) revisa que sus datos de contacto esten correctos antes de correr.
EXEC :historia_cursor := PA_PARTICIPANTE.CONSULTAR_MIS_DATOS(1001);
PRINT historia_cursor;

PROMPT Paso 3: Carlos termina el primer segmento de la carrera y registra su tiempo exitosamente.
EXEC PA_PARTICIPANTE.REGISTRAR_TIEMPO(10, 300, 1, 1001, 'V01', 'SEG1');

PROMPT Paso 4: Carlos revisa la tabla global para confirmar si su tiempo entro en el Top 5.
EXEC :historia_cursor := PA_PERSONA.VER_MEJORES_TIEMPOS();
PRINT historia_cursor;

PROMPT Paso 5: Por un error de red, la app de Carlos intenta enviar exactamente el mismo registro de nuevo (Accion no permitida por duplicidad).
BEGIN
    PA_PARTICIPANTE.REGISTRAR_TIEMPO(10, 300, 1, 1001, 'V01', 'SEG1');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Sistema protegio los datos: No se puede registrar un tiempo duplicado (' || SQLERRM || ')');
END;
/

PROMPT Paso 6: Carlos continua la carrera y registra su tiempo en el segundo segmento sin problemas.
EXEC PA_PARTICIPANTE.REGISTRAR_TIEMPO(11, 450, 2, 1001, 'V01', 'SEG2');

PROMPT Paso 7: La aplicacion falla al calcular el tiempo del tercer segmento y envia un valor negativo (Accion no permitida por regla de negocio).
BEGIN
    PA_PARTICIPANTE.REGISTRAR_TIEMPO(12, -50, 3, 1001, 'V01', 'SEG3');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Sistema protegio los datos: El tiempo no puede ser negativo (' || SQLERRM || ')');
END;
/

PROMPT Paso 8: Carlos corrige el error en su dispositivo y envia el tiempo real positivo.
EXEC PA_PARTICIPANTE.REGISTRAR_TIEMPO(12, 500, 3, 1001, 'V01', 'SEG3');

PROMPT Paso 9: Otro ciclista rival (ID 1002) registra un tiempo mucho mejor en el primer segmento, superando a Carlos.
EXEC PA_PARTICIPANTE.REGISTRAR_TIEMPO(13, 280, 1, 1002, 'V01', 'SEG1');

PROMPT Paso 10: Al final del dia, los participantes consultan la tabla final de mejores tiempos para ver quien gano.
EXEC :historia_cursor := PA_PERSONA.VER_MEJORES_TIEMPOS();
PRINT historia_cursor;

PROMPT ==========================================================
PROMPT Prueba de aceptacion finalizada con exito.
PROMPT ==========================================================


-- ====================================================================
-- XSeguridad
-- ====================================================================

/*
-- Instrucciones para eliminar los roles de seguridad creados previamente
DROP ROLE R_PARTICIPANTE;
DROP ROLE R_PERSONA;
*/
