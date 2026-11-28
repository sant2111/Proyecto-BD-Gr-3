   # Sistema de Gestión de Biblioteca — Proyecto Integrador
   **Curso 750006C Bases de Datos · Universidad del Valle · Grupo 3**

   Repositorio del proyecto integrador para la gestión de préstamos, usuarios, catálogo de libros y reportes de biblioteca sobre PostgreSQL.

   ---

   ## 🚀 Requisitos Previos

   Solo es necesario tener instalados:
   * [Docker](https://docs.docker.com/get-docker/)
   * [Docker Compose](https://docs.docker.com/compose/)

   ---

   ## 🛠️ Cómo levantar el entorno (PostgreSQL + pgAdmin)

   1. **Clonar el repositorio:**
      ```bash
      git clone https://github.com/sant2111/Proyecto-BD-Gr-3.git
      cd Proyecto-BD-Gr-3
      ```

   2. **Iniciar los servicios con Docker Compose:**
      ```bash
      docker compose up -d
      ```
      *Esto descargará las imágenes, iniciará PostgreSQL (puerto 5432) y creará automáticamente las tablas del esquema `biblioteca` definidas en `postgres/init/01_esquema.sql`.*

   3. **Verificar el estado:**
      ```bash
      docker compose ps
      ```

   ---

   ## 🖥️ Acceso a pgAdmin 4 (Interfaz Web)

   El entorno incluye **pgAdmin 4** preconfigurado:

   1. Abre tu navegador en: [http://localhost:5050](http://localhost:5050)
   2. **Credenciales de inicio de sesión:**
      * **Email:** `admin@admin.com`
      * **Contraseña:** `admin`
   3. En el panel izquierdo de pgAdmin verás el servidor **"Biblioteca (PostgreSQL)"** ya registrado. Haz clic sobre él e ingresa la contraseña de la base de datos: `curso`.

   ---

   ## 🗄️ Carga de Datos Semilla

   Para poblar las tablas con los datos semilla del curso:

   1. **Cargar Libros:**
      ```bash
      docker compose exec postgres psql -U curso -d curso -f /scripts/carga-libros.sql
      ```

   2. **Cargar Lectores:**
      ```bash
      docker compose exec postgres psql -U curso -d curso -f /scripts/carga-lectores.sql
      ```

   ## Lógica en la base de datos

   | Objeto | Tipo | Tabla y evento | Regla que implementa |
   | :--- | :--- | :--- | :--- |
   | `biblioteca.registrar_prestamo(p_documento, p_isbn, p_id_ejemplar)` | Procedimiento | — | Registra un préstamo con plazo de 14 días validando que el lector y el ejemplar existan, y que el ejemplar no tenga otro préstamo abierto (`fecha_devolucion IS NULL`). |
   | `biblioteca.validar_prestamo()` | Función | — | Función asociada al trigger que bloquea al lector (`FOR UPDATE`) y verifica que no tenga préstamos vencidos sin devolver ni 3 o más préstamos abiertos. |
   | `validar_prestamo_antes_insertar` | Trigger | `biblioteca.prestamo` (`BEFORE INSERT`) | Impide insertar un préstamo si el lector tiene préstamos vencidos sin devolver o ya alcanzó el máximo de 3 préstamos abiertos, aplicando la regla incluso sin llamar al procedimiento. |



   ## 💻 Consola Interactiva (psql)

   Si prefieres trabajar desde la terminal:
   ```bash
   docker compose exec postgres psql -U curso -d curso
   ```
   Dentro de `psql`, fija el esquema por defecto:
   ```sql
   SET search_path TO biblioteca;
   SELECT count(*) FROM libro;
   SELECT count(*) FROM lector;
   ```

   ---

   ## 📁 Estructura del Repositorio

   ```text
   Proyecto-BD-Gr-3/
   ├── docker-compose.yml       # Orquestación de PostgreSQL 16 y pgAdmin 4
   ├── .gitignore               # Exclusión de volúmenes locales y temporales
   ├── pgadmin/
   │   └── servers.json         # Autoconfiguración del servidor en pgAdmin
   ├── postgres/
   │   ├── init/
   │   │   ├── 01_esquema.sql       # DDL del esquema 'biblioteca' (se ejecuta al iniciar)
   │   │   └── 02_programacion.sql  # Funciones, procedimientos y triggers (Hito 4)
   │   └── scripts/
   │       ├── carga-libros.sql         # Script ETL con validaciones para libros
   │       ├── carga-lectores.sql       # Script ETL con validaciones para lectores
   │       ├── programacion.sql         # Definición de lógica en BD (Hito 4)
   │       ├── pruebas-programacion.sql # Batería de pruebas de reglas y triggers (Hito 4)
   │       └── datos/                   # Archivos CSV semilla y pruebas
   ├── evidencias/              # Logs y capturas de verificación por hito
   └── docs/                    # Documentación, definición, normalización y talleres
   ```

   ---

   ## 🛑 Cómo detener el entorno

   * **Detener los contenedores:**
   ```bash
   docker compose stop
   ```
   * **Apagar y remover contenedores:**
   ```bash
   docker compose down
   ```
