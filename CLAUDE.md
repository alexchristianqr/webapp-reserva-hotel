# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Sistema de reservas para "Hotel Tierra Colorada". Aplicación web Java tradicional (JSP + Servlets) desplegada en Apache Tomcat 10, con Vue.js 3 en el frontend vía CDN para reactividad en formularios.

## Build & Deploy

Este proyecto usa **Apache Ant** con NetBeans como IDE. No hay npm, Maven ni Gradle.

**Construir el proyecto:**
```bash
ant clean build
```

**Generar WAR para deploy:**
```bash
ant dist
# Genera dist/webapp-reserva-hotel.war
```

**Deploy en Tomcat:**
- Copiar el WAR a `D:/apache-tomcat-10.1.12/webapps/`
- O usar la tarea Ant de deploy de NetBeans (nbproject/ant-deploy.xml)

**Ejecutar desde NetBeans:**
- Run Project (F6) — inicia Tomcat y despliega automáticamente
- La app queda accesible en: `http://localhost:8080/webapp-reserva-hotel`

## Base de datos

**MySQL local, sin contraseña:**
```
Host: 127.0.0.1:3306
Database: db_hotel
User: root
Password: (vacío)
```

El esquema completo está en `db_hotel.sql`. Importarlo antes de correr la app:
```bash
mysql -u root db_hotel < db_hotel.sql
```

La conexión está hardcodeada en `src/java/core/services/MysqlDBService.java`.

## Arquitectura

### Flujo de una petición

```
JSP (Fetch API) → @WebServlet → Controller → Service → MysqlDBService → MySQL
                                                      ← ResponseService<T> (JSON)
```

### Capas

| Capa | Paquete | Responsabilidad |
|------|---------|----------------|
| Vistas | `web/*.jsp` | Templates JSP + Vue.js reactivo |
| Servlets | `src/java/servlets/` | Mapeo HTTP, lectura de parámetros, escritura JSON |
| Controllers | `src/java/controllers/` | Orquestación de lógica de negocio |
| Services | `src/java/services/` | Reglas de negocio y acceso a datos |
| Core DB | `src/java/core/services/MysqlDBService.java` | Ejecución de queries JDBC |

### Clases base importantes

- **`BaseServlet`** (`core/servlets/`) — verifica sesión activa; devuelve 401 + `redirectUrl` si no hay sesión. Todos los servlets lo extienden.
- **`BaseService`** — inyecta una instancia de `MysqlDBService` en cada servicio.
- **`ResponseService<T>`** — wrapper JSON estándar para todas las respuestas: `{success, message, result, code, redirectUrl}`.
- **`Persona`** — clase abstracta base para `Cliente` y `Empleado`.

### Autenticación

- Sesión HTTP server-side (`HttpSession`).
- Login/logout en `AutenticacionServlet` (`/AutenticacionServlet`) con parámetro `action=login|logout`.
- El usuario autenticado se guarda en sesión como `"usuario"`.
- `UsuarioThreadLocal` propaga el usuario al hilo actual para acceso desde servicios.

### Métodos de MysqlDBService

```java
queryConsultar(sql, params)   // SELECT → List<Object[]>
queryInsertar(sql, params)    // INSERT → int (id generado)
queryActualizar(sql, params)  // UPDATE → boolean
queryEliminar(sql, params)    // DELETE → boolean
```

### Frontend (JSP + Vue.js 3 CDN)

- Bootstrap 5.3.3 + Bootstrap Icons 1.11.3 cargados desde CDN en `web/includes/header.jsp`.
- Vue.js 3 usado con `reactive()` para formularios; no hay componentes SFC ni build step.
- Las peticiones usan `fetch()` nativo con `FormData` (POST) hacia los servlets.
- `header.jsp` y `footer.jsp` se incluyen con `<%@ include file="..." %>` en cada página.

## Dependencias externas (JARs en /libs)

| JAR | Versión | Uso |
|-----|---------|-----|
| `gson-2.10.1.jar` | 2.10.1 | Serialización Java → JSON |
| `mysql-connector-j-8.2.0.jar` | 8.2.0 | Driver JDBC MySQL |

No hay gestor de dependencias; los JARs se referencian directamente desde `nbproject/project.properties`.

## Stack tecnológico

- **Java 21** / **Jakarta EE 10** (paquetes `jakarta.servlet.*`)
- **Apache Tomcat 10.1.12**
- **MySQL 8** con JDBC directo (sin ORM)
- **Apache Ant** como build tool
- **NetBeans** como IDE (configuración en `nbproject/`)
