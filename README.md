<!-- Encabezado principal con estilo centrado -->
<h1 align="center">⚡ Lumin Database System</h1>
<h3 align="center">El núcleo inteligente de la plataforma educativa adaptativa para aprender Python</h3>

<p align="center">

  <!-- Identidad del proyecto -->
  <img src="https://img.shields.io/badge/LUMIN-Project-6A5ACD?style=for-the-badge" />

  <!-- Arquitectura -->
  <img src="https://img.shields.io/badge/Database-Architecture-2453FF?style=for-the-badge&logo=oracle" />

  <!-- Oracle -->
  <img src="https://img.shields.io/badge/Oracle-19c_/_21c-F80000?style=for-the-badge&logo=oracle&logoColor=white" />

  <!-- PL/SQL -->
  <img src="https://img.shields.io/badge/PL/SQL-Advanced-F28C28?style=for-the-badge" />

  <!-- Cloud -->
  <img src="https://img.shields.io/badge/Cloud-Oracle_OCI-CC0000?style=for-the-badge&logo=oracle" />

  <!-- Python -->
  <img src="https://img.shields.io/badge/Backend-Python-3776AB?style=for-the-badge&logo=python&logoColor=white" />

  <!-- FastAPI -->
  <img src="https://img.shields.io/badge/API-FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white" />

  <!-- Kotlin -->
  <img src="https://img.shields.io/badge/Android-Kotlin-7F52FF?style=for-the-badge&logo=kotlin&logoColor=white" />

</p>

---

## 📘 Descripción General

**Lumin** es una plataforma móvil que moderniza el aprendizaje de Python mediante **gamificación**, **progresión adaptativa** y **evaluación dinámica**.

Este repositorio contiene el **diseño completo de la Base de Datos Oracle**, la cual actúa como:

> 🎯 **El cerebro del sistema**, centralizando reglas de negocio críticas en PL/SQL para máxima seguridad, integridad y eficiencia.

### 🔗 Componentes del Ecosistema

| Componente | Descripción |
|-----------|-------------|
| 📱 **Android App (Kotlin)** | Interfaz principal del usuario. |
| 🐍 **Backend Python** | API con Flask/FastAPI conectada mediante Oracle Client. |
| 🗃️ **Oracle Database** | Este repositorio: lógica, estructuras y reglas del sistema. |

---

## 🚀 Características Destacadas

### 🧠 Lógica de Negocio Encapsulada en PL/SQL
Diseñada con enfoque **Data-Centric**:  
Las reglas no están en la App ni en el Backend, sino **dentro de la Base de Datos**.

🔹 `PKG_PROGRESS`: cálculo de notas, aprobación automática, avance y desbloqueo de contenido.  
🔹 `PKG_ACCOUNT`: sistema de vidas con regeneración temporal y control de concurrencia.  
🔹 `PKG_SUBSCRIPTION`: manejo de planes Free/Premium, expiración y auditoría financiera.

---

### 🛡️ Seguridad y Auditoría

- **RBAC (Roles de Acceso):**  
  - `RO_LUMIN_APP` → acceso limitado para la app  
  - `RO_LUMIN_ADMIN` → permisos elevados para administración  
- **Auditoría de Cambios:**  
  Triggers que registran modificaciones sensibles en `AUDIT_LOG`.
- **SQL Injection Safe:**  
  Todos los métodos usan *bind variables* y validación interna.

---

## 📂 Estructura del Proyecto

```text
/
├── 01_Esquema_Tablas.sql        # Tablas, llaves foráneas y auditoría
├── 02_Objetos_Adicionales.sql   # Índices, roles, vistas y seguridad
├── 03_Carga_Datos.sql           # Seed inicial (cursos, módulos, niveles)
├── 04_Programacion_PLSQL.sql    # Packages, triggers y procedimientos
├── Entregable_3_Scripts/        # Scripts de mantenimiento y pruebas
└── README.md                    # Este documento
```

---

## 🗃️ Modelo de Datos

El diseño respeta plenamente **3FN**, garantizando integridad y consistencia.

### 📑 Entidades Principales

| Tabla | Rol |
|-------|-----|
| **APP_USER** | Identidad y perfil del usuario. |
| **SECTION / MODULE** | Organización curricular jerárquica. |
| **PRACTICE_ATTEMPT** | Registro transaccional de ejercicios. |
| **SUBSCRIPTION** | Historial y estados de suscripciones. |
| **USER_ACCOUNT** | Gestión de vidas, racha y estados de juego. |

> 📌 *El diagrama ER completo está disponible en la carpeta de documentación.*

---

## ⚙️ Despliegue (Oracle Always Free – Autonomous Database)

El proyecto está optimizado para ejecutarse en **Oracle Autonomous Database Always Free**, lo cual requiere autenticación mediante **Wallet**.

---

### 🧩 Requisitos Previos

✔ Tener una cuenta Oracle Cloud (OCI)  
✔ Haber creado una instancia **Autonomous Database (ATP)** en modo Always Free  
✔ Descargar la **Client Wallet** desde OCI  
✔ Tener instalado Oracle SQL Developer, SQLcl o cualquier cliente compatible

---

## 📥 1. Descargar la Wallet desde Oracle Cloud

1. Inicia sesión en OCI  
2. Navega a: **Autonomous Database → Tu Instancia → DB Connection**  
3. Haz clic en **Download Wallet**  
4. Especifica una contraseña para el archivo ZIP  
5. Guarda el archivo `Wallet_LUMIN.zip` en tu equipo

> ⚠️ Importante: No subas la wallet al repositorio. Debe manejarse como secreto.

---

## 📦 2. Configurar la Wallet en tu máquina

1. Descomprime el archivo ZIP  
2. Copia los archivos dentro de tu carpeta de Oracle Client o SQL Developer  
3. Establece la variable de entorno:

### En Windows:
```powershell
set TNS_ADMIN=C:\ruta\a\Wallet_LUMIN
```

### En macOS / Linux:
```bash
export TNS_ADMIN=/Users/tuusuario/Wallet_LUMIN
```

---

## 🔗 3. Conexión a la Base de Datos

Usa uno de los alias incluidos en `tnsnames.ora`, por ejemplo:  
- `lumin_high`  
- `lumin_medium`  
- `lumin_low`

Ejemplo con SQLcl:

```bash
sql admin@lumin_high
```

Se te pedirá la contraseña del usuario ADMIN configurado al crear la base de datos.

---

## 🏗️ 4. Ejecución de Scripts del Proyecto

Ejecuta los scripts **en orden**, conectándote como `ADMIN` o como un usuario con privilegios de creación:

```
01_Esquema_Tablas.sql
02_Objetos_Adicionales.sql
03_Carga_Datos.sql
04_Programacion_PLSQL.sql
```

En SQL Developer o SQLcl:

```sql
@01_Esquema_Tablas.sql
@02_Objetos_Adicionales.sql
@03_Carga_Datos.sql
@04_Programacion_PLSQL.sql
```

---

## 🔎 5. Validar Compilación y Objetos

```sql
SELECT object_name, object_type 
FROM user_objects 
WHERE status = 'INVALID';
```

Si no hay resultados → Todo está correctamente instalado ✔

---

## 🌐 6. Conexión desde Backend Python (Wallet Required)

```python
import oracledb

oracledb.init_oracle_client(lib_dir="C:/oracle/instantclient", 
                            config_dir="C:/ruta/Wallet_LUMIN")

conn = oracledb.connect(
    user="LUMIN_BACKEND",
    password="tu_password",
    dsn="lumin_high"  # alias desde tnsnames.ora
)

cursor = conn.cursor()
cursor.callproc("PKG_ACCOUNT.GET_LIVES", [user_id, result_out])
```

> 📌 *El backend siempre usa alias TNS y necesita acceso al archivo wallet.*

---
## 7.🎥📱 Recursos del Proyecto (Video Demo + APK)

Para complementar la documentación técnica y mostrar el funcionamiento real de Lumin, hemos preparado una carpeta pública con:

🎬 Video de presentación del proyecto

📦 APK instalable de la aplicación Android

<p align="center"> <a href="https://drive.google.com/drive/folders/1utLqDLVvbOoHE07d9MTmp_pc22Jr0oQn" target="_blank"> <img src="https://img.shields.io/badge/Google_Drive-Recursos_del_Proyecto-34A853?style=for-the-badge&logo=google-drive&logoColor=white" /> </a> </p>

📌 Haz clic en el badge para acceder al video y al APK.

---

## 👥 Equipo de Desarrollo

| Miembro | Rol / Responsabilidades |
|--------|---------------------------|
| 🧑‍💻 **Nick Salcedo** | AI Engineer — Diseño, desarrollo e integración del chatbot y sistemas basados en IA. |
| 🧑‍💻 **Gabriel Dávalos** | Full Stack Developer — Implementación de funcionalidades en frontend y backend, soporte en integración general. |
| 🧑‍💻 **Leonidas García** | Frontend Developer & UI/UX — Desarrollo de la interfaz de usuario, experiencia de usuario y optimización visual. |
| 🧑‍💻 **Jorge Luque** | Database Engineer & Backend Support — Diseño y desarrollo del modelo de datos, estructuración de la base de datos e implementación de endpoints del backend. |
| 🧑‍💻 **Fabrizio Mantari** | Backend Developer — Desarrollo de endpoints, lógica del servidor e integración con la base de datos. |


---

<br>

<p align="center">
  <strong>Hecho con 💙, café y pasión por la ingeniería — Lima, Perú 2025</strong>
</p>
