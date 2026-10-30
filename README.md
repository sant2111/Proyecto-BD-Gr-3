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

---

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
│   │   └── 01_esquema.sql   # DDL del esquema 'biblioteca' (se ejecuta al iniciar)
│   └── scripts/
│       ├── carga-libros.sql # Script ETL con validaciones para libros
│       ├── carga-lectores.sql # Script ETL con validaciones para lectores
│       └── datos/           # Archivos CSV semilla y pruebas
└── docs/                    # Enunciado y guías del curso
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
