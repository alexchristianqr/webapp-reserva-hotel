# syntax=docker/dockerfile:1

# ---------- Stage 1: build del WAR con Maven (Java 21) ----------
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app

# Cachear dependencias: primero el pom, luego el codigo fuente
COPY pom.xml ./
RUN mvn -q -B -e dependency:go-offline

COPY src ./src
RUN mvn -q -B clean package -DskipTests

# ---------- Stage 2: runtime Tomcat 10.1 + JRE 21 ----------
FROM tomcat:10.1-jre21-temurin

# Desplegar la app como ROOT (servida en "/") para que el ALB acceda
# directamente a /api/health y /login.jsp sin el context path.
RUN rm -rf "${CATALINA_HOME}/webapps/ROOT"
COPY --from=build /app/target/webapp-reserva-hotel.war "${CATALINA_HOME}/webapps/ROOT.war"

EXPOSE 8080
CMD ["catalina.sh", "run"]
