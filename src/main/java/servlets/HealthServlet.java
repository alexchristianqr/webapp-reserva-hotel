package servlets;

import java.io.IOException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

/**
 * Endpoint de salud para el health check del Application Load Balancer (AWS).
 *
 * Extiende {@link HttpServlet} directamente (NO {@code core.servlets.BaseServlet})
 * porque BaseServlet exige sesion autenticada y responderia 401, marcando el
 * target como unhealthy. No consulta la BD para que el chequeo sea liviano y
 * no falle por la conexion.
 */
@WebServlet(name = "HealthServlet", urlPatterns = {"/api/health"})
public class HealthServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        response.setStatus(HttpServletResponse.SC_OK);
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        response.getWriter().write("{\"status\":\"UP\"}");
    }
}
