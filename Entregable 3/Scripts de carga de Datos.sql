-- Carga de Planes de Suscripción

INSERT INTO SUBSCRIPTION_PLAN (NAME, DURATION_DAYS, PRICE)
VALUES ('Lumin Pro', 30, 2.99);

INSERT INTO SUBSCRIPTION_PLAN (NAME, DURATION_DAYS, PRICE)
VALUES ('Lumin Ultra', 365, 20.99);

COMMIT;

-- Carga de Contenido del Curso (Niveles y Secciones)

INSERT INTO LEVELS (NAME) VALUES ('Básico');
INSERT INTO LEVELS (NAME) VALUES ('Intermedio');
INSERT INTO LEVELS (NAME) VALUES ('Avanzado');

-- Secciones para el nivel basico
INSERT INTO SECTION (ID_LEVEL, NAME) VALUES (1, 'Ejecución secuencial e Instrucciones');
INSERT INTO SECTION (ID_LEVEL, NAME) VALUES (1, 'Abstracción de Datos');
INSERT INTO SECTION (ID_LEVEL, NAME) VALUES (1, 'Interacción y representación de datos (Entrada y Salida)');
INSERT INTO SECTION (ID_LEVEL, NAME) VALUES (1, 'Listas');
INSERT INTO SECTION (ID_LEVEL, NAME) VALUES (1, 'Tuplas');
INSERT INTO SECTION (ID_LEVEL, NAME) VALUES (1, 'Conjuntos (Sets)');
INSERT INTO SECTION (ID_LEVEL, NAME) VALUES (1, 'Diccionarios');
INSERT INTO SECTION (ID_LEVEL, NAME) VALUES (1, 'Condicionales');
INSERT INTO SECTION (ID_LEVEL, NAME) VALUES (1, 'Bucles');

-- Secciones para el nivel intermedio
INSERT INTO SECTION (ID_LEVEL, NAME) VALUES (2, 'Funciones y modularidad');
INSERT INTO SECTION (ID_LEVEL, NAME) VALUES (2, 'Manejo de excepciones');
INSERT INTO SECTION (ID_LEVEL, NAME) VALUES (2, 'Paradigmas de programación');
INSERT INTO SECTION (ID_LEVEL, NAME) VALUES (2, 'POO I');
INSERT INTO SECTION (ID_LEVEL, NAME) VALUES (2, 'POO II');
INSERT INTO SECTION (ID_LEVEL, NAME) VALUES (2, 'Estructuras de datos fundamentales I');
INSERT INTO SECTION (ID_LEVEL, NAME) VALUES (2, 'Estructuras de datos fundamentales II');

--  Secciones para el nivel avanzado
INSERT INTO SECTION (ID_LEVEL, NAME) VALUES (3, 'Notación asintótica (Big O notation y complejidades)');
INSERT INTO SECTION (ID_LEVEL, NAME) VALUES (3, 'Diseño de algoritmos');
INSERT INTO SECTION (ID_LEVEL, NAME) VALUES (3, 'Algoritmos de ordenación');
INSERT INTO SECTION (ID_LEVEL, NAME) VALUES (3, 'Algoritmos de búsqueda');
INSERT INTO SECTION (ID_LEVEL, NAME) VALUES (3, 'Siguientes pasos');

COMMIT;

-- Carga de Páginas en este caso solo de la Seccion 1 

DECLARE
  v_id_tm_1 NUMBER;
BEGIN
  SELECT ID_THEORY_MODULE
    INTO v_id_tm_1
    FROM THEORY_MODULE
   WHERE ID_SECTION = 1; 
   
 -- Página 1: Introducción a Programas
  INSERT INTO page (id_theory_module, name, page_order, content_md)
  VALUES (v_tm_id,
          '¿Qué es un Programa?',
          1,
          q'~Un **programa** (o _software_) es un conjunto de **instrucciones** lógicas, precisas y ordenadas, que le decimos a una computadora que ejecute para lograr un objetivo específico.

Piensa en un programa como una **receta detallada**: la computadora es el chef, y las instrucciones le indican exactamente qué pasos seguir, en qué orden y con qué ingredientes (datos).

| **Concepto**      | **Definición**                                                                                         |
| ----------------- | ------------------------------------------------------------------------------------------------------ |
| **Instrucción**   | La orden más simple que la CPU puede entender: guardar un dato, sumar dos números, mostrar un mensaje. |
| **Código Fuente** | El texto (la "receta") escrito por el programador en un lenguaje que es legible para humanos.          |
| **Ejecución**     | El proceso en el que la computadora sigue las instrucciones del código fuente.                         |

## Introducción al Lenguaje de Programación: Python

A lo largo de este curso, utilizaremos **Python**. Python es un lenguaje de **alto nivel**, lo que significa que es muy similar al idioma inglés y está diseñado para ser fácil de leer y escribir. Esto nos permite centrarnos en los conceptos de programación sin distraernos con sintaxis compleja.

Python es extremadamente popular debido a su **simplicidad y versatilidad**, siendo utilizado en desarrollo web, análisis de datos, inteligencia artificial y automatización.

## Ejemplos de Instrucciones Básicas en Python

A continuación, se muestra cómo se ven las instrucciones básicas que estudiaremos en Python:

- Ordena la computadora a mostrar el mensaje en pantalla
```python
print("Hola Lumin")
```
```txt
Output: Hola Lumin
```

- Ordena a la computadora guardar el valor 25 en el **contenedor** llamado edad
```python
edad = 25
```

- Ordena sumar y guardar el resultado (`8`) en el contenedor llamado `suma`.
```python
suma = 5 + 3
```

En las siguientes páginas, aprenderemos cómo la computadora ejecuta estas instrucciones de manera **secuencial**.~');

  -- Página 2: Ejecución Secuencial
  INSERT INTO page (id_theory_module, name, page_order, content_md)
  VALUES (v_tm_id,
          'Ejecución Secuencial',
          2,
          q'~La **Ejecución Secuencial** es el principio más fundamental del flujo de programa: las instrucciones se ejecutan una después de la otra, **en el orden exacto en que aparecen en el código**, de arriba hacia abajo.

## La Regla de Oro del Flujo

1. La computadora lee la **Línea 1**.
2. La ejecuta y la completa.
3. Solo entonces, pasa a leer y ejecutar la **Línea 2**.
4. Este proceso continúa hasta que se alcanza la última instrucción del programa.

Este orden estricto es lo que garantiza la **predecibilidad**. El valor de una variable en la Línea 5 depende de los cálculos realizados en las líneas 1 a 4. Si el orden cambiara, el resultado sería incorrecto.

## Ejemplo con Python

Considera el siguiente código. Nota cómo la salida del programa (el valor de `c`) se define completamente por la secuencia de las tres líneas anteriores:

|Línea|Instrucción en Python|Flujo de Ejecución (Paso a Paso)|
|---|---|---|
|**1**|`a = 10`|La computadora guarda el número **10** en la memoria con el nombre `a`.|
|**2**|`b = 5`|La computadora guarda el número **5** en la memoria con el nombre `b`.|
|**3**|`c = a + b`|La computadora **lee los valores actuales** de `a` (10) y `b` (5), los suma, y guarda el resultado **15** en `c`.|
|**4**|`print(c)`|La computadora muestra el valor actual de `c`. **Salida: 15**|

## Consecuencias de la Secuencia

La ejecución secuencial tiene dos implicaciones clave:

1. **Dependencia:** Si intentaras usar la variable `c` en la Línea 2, el programa fallaría, ya que `c` aún no ha sido definida por la operación en la Línea 3.
2. **Sobreescritura:** Una instrucción posterior siempre **sobrescribe** el resultado de una instrucción anterior si ambas usan la misma variable.

### Ejemplo de Sobreescritura:
```python
x = 5
x = 10
print(x)
```
```txt
Output: 10
```

En este caso, la Línea 2 se ejecuta _después_ de la Línea 1, lo que resulta en la pérdida del valor original `5`.~');

  -- Página 3: Tipos de Instrucciones
  INSERT INTO page (id_theory_module, name, page_order, content_md)
  VALUES (v_tm_id,
          'Tipos de instrucciones',
          3,
          q'~Aunque las instrucciones varían entre lenguajes, todas cumplen una de estas funciones básicas para que el programa pueda interactuar y procesar datos.

## 1. Instrucciones de Asignación

Son la base para almacenar y manipular datos. Estas instrucciones **guardan un valor** en un contenedor de memoria llamado **variable**.

| Concepto       | Descripción                                                                        | Ejemplo en Python       |
| -------------- | ---------------------------------------------------------------------------------- | ----------------------- |
| **Asignación** | Define o actualiza el valor de una variable, usando el operador de igualdad (`=`). | `precio = 45.99`        |
| **Cálculo**    | Combina la asignación con operadores aritméticos (`+`, `-`, `*`, `/`).             | `total = precio * 1.15` |
| **Lógica**     | Combina valores y produce un resultado Booleano (`True` o `False`).                | `es_mayor = edad > 18`  |

## 2. Instrucciones de Entrada/Salida (I/O)

Permiten al programa comunicarse con el mundo exterior (el usuario, un archivo, la red, etc.).

|Tipo|Función|Ejemplo en Python|
|---|---|---|
|**Salida (Output)**|Muestra datos o resultados al usuario, generalmente en la consola.|`print("El total es:", total)`|
|**Entrada (Input)**|Permite al programa recibir datos del usuario. El programa **espera** hasta que el usuario ingresa la información.|`nombre = input("Dime tu nombre: ")`|

**Nota sobre la Secuencia:** Cuando la computadora llega a una instrucción `input()`, la ejecución secuencial **se pausa** hasta que el usuario presiona Enter.

## 3. Instrucciones de Control de Flujo

Estas son las instrucciones que **rompen** la regla de la ejecución secuencial. En lugar de seguir la línea siguiente, deciden si saltar, repetir o tomar un camino diferente.

|Tipo|Propósito|Ejemplo (Concepto)|
|---|---|---|
|**Condicionales**|Tomar decisiones. Ejecutar un bloque de código **SOLO SI** se cumple una condición (ej. `IF-THEN-ELSE`).|Si la edad es mayor a 18, imprimir "Adulto".|
|**Bucles**|Repetir un bloque de código varias veces hasta que se cumpla una condición de parada.|Repetir 10 veces la instrucción de imprimir.|

Las instrucciones de control de flujo son esenciales, ya que un programa que solo se ejecuta secuencialmente es muy limitado. Estas serán exploradas en detalle en secciones posteriores.~');

  -- Página 4: Sintaxis y Errores
  INSERT INTO page (id_theory_module, name, page_order, content_md)
  VALUES (v_tm_id,
          'Sintaxis y Errores',
          4,
          q'~Para que un programa pueda ser ejecutado **secuencialmente**, cada instrucción debe estar escrita correctamente. Aquí es donde entra en juego la sintaxis y el manejo de errores.

## 1. La Sintaxis: La Gramática del Código

La **Sintaxis** es el conjunto de reglas que definen cómo deben estructurarse las instrucciones en un lenguaje de programación. Es la gramática que el intérprete (en este caso, Python) entiende.

- **En Lenguaje Humano:** Las reglas de sintaxis definen que una oración debe terminar con un punto o que los nombres deben empezar con mayúscula.
- **En Python:** Las reglas definen el uso correcto de dos puntos (`:`) después de una condición o el uso obligatorio de la **indentación** (espacios o tabulaciones) para definir bloques de código.

**Ejemplo de Sintaxis Correcta:**
```python
if 5 > 2:
    print("Cinco es mayor")
```
```txt
Output: Cinco es mayor
```

## 2. El Error de Sintaxis (`SyntaxError`)

Un **Error de Sintaxis** ocurre cuando el programador rompe las reglas del lenguaje.

- **Consecuencia:** Si el intérprete encuentra un error de sintaxis, no puede traducir la instrucción. La ejecución secuencial **se detiene inmediatamente** y el programa no puede continuar.

- **Identificación:** El intérprete generalmente señala la línea y la columna donde se detectó el error, lo que facilita al programador corregirlo.

**Ejemplo de Error de Sintaxis en Python:**
```python
if 10 == 10
    print("Faltan dos puntos")
```
```txt
Output: SyntaxError: invalid syntax
```

## 3. La Clave de la Ejecución Secuencial y los Errores

Es importante notar la diferencia entre un error de sintaxis y la lógica incorrecta:

|Tipo de Error|¿Cuándo Ocurre?|¿Detiene la Secuencia?|
|---|---|---|
|**Sintaxis**|Antes de que el código comience a ejecutarse.|**SÍ.** El intérprete no puede traducir el código.|
|**Lógico**|Durante la ejecución (por ejemplo, una variable no existe o una operación es imposible).|SÍ, pero solo **en la línea del error**.|

Ejemplo de Error Lógico (en Tiempo de Ejecución):
```python
a = 10
b = 0
c = a / b
print("Fin")
```
```txt
Output: ZeroDivisionError: division by zero
```

En conclusión, la **ejecución secuencial** solo es posible si cada línea, desde la primera hasta la última, respeta rigurosamente la **sintaxis** del lenguaje.~');

COMMIT;
END;
/