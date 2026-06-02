@echo off
REM ============================================================
REM  Compila, despliega y arranca webapp-reserva-hotel en Tomcat
REM  Requisitos: MySQL (XAMPP) corriendo con la BD db_hotel
REM  Ajusta las 3 rutas de abajo si cambian en tu equipo.
REM ============================================================
setlocal
set "JAVA_HOME=C:\Program Files\Java\jdk-21"
set "CATALINA_HOME=D:\apache-tomcat-10.1.12"
set "MVN=C:\Program Files\JetBrains\IntelliJ IDEA 2026.1.2\plugins\maven\lib\maven3\bin\mvn.cmd"

echo [1/3] Compilando WAR con Maven...
call "%MVN%" -q clean package
if errorlevel 1 (echo *** Fallo el build de Maven *** & pause & exit /b 1)

echo [2/3] Desplegando WAR en Tomcat...
copy /Y "%~dp0target\webapp-reserva-hotel.war" "%CATALINA_HOME%\webapps\webapp-reserva-hotel.war" >nul

echo [3/3] Arrancando Tomcat...  (cierra esta ventana o Ctrl+C para detener)
echo.
echo     App:   http://localhost:8080/webapp-reserva-hotel/login.jsp
echo     Login: alex.quispe@gmail.com  /  12345678
echo.
call "%CATALINA_HOME%\bin\catalina.bat" run
endlocal
