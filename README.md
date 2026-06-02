# webapp-reserva-hotel

Migración del proyecto Web de NetBeans a una estructura compatible con IntelliJ IDEA mediante Maven.

## Qué cambió

- Se agregó `pom.xml` para abrir el proyecto como **Maven Web App** en IntelliJ IDEA.
- Se conservaron las rutas originales:
  - código Java en `src/java`
  - recursos web en `web`
- Se agregó una prueba de humo con JUnit 5 en `src/test/java`.
- Se mantiene el proyecto legado de NetBeans para referencia, pero el arranque recomendado ahora es Maven.

## Requisitos

- Java 21
- Maven 3.9+ (o el Maven embebido de IntelliJ IDEA)
- Tomcat 10.1.x para ejecutar la aplicación como WAR
- MySQL 8 con la base `db_hotel`

## Cómo abrir en IntelliJ IDEA

1. Abre la carpeta raíz del proyecto.
2. Si IntelliJ pregunta el tipo de proyecto, elige **Maven**.
3. Verifica que el SDK sea **Java 21**.
4. Espera a que descargue dependencias y reindexe el proyecto.

## Build

```bash
mvn clean test
mvn clean package
```

El WAR se genera en:

```bash
target/webapp-reserva-hotel.war
```

## Ejecutar en Tomcat

### Opción recomendada

1. Copia `target/webapp-reserva-hotel.war` a tu Tomcat 10.1.x.
2. Inicia Tomcat.
3. Abre la app en el contexto:

```text
/webapp-reserva-hotel
```

### En IntelliJ IDEA Ultimate

- Configura un servidor Tomcat 10.1.x.
- Despliega el WAR generado por Maven.

## Base de datos

La conexión sigue apuntando a:

- Host: `127.0.0.1:3306`
- Database: `db_hotel`
- User: `root`
- Password: vacío

Si necesitas cambiarlo, edita `src/java/core/services/MysqlDBService.java`.

