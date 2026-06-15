package servlets;

import core.servlets.BaseServlet;
import java.io.IOException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import services.ReporteService;

// Sirve reportes PDF. A diferencia del resto de servlets (que responden JSON),
// éste escribe directamente el binario application/pdf para que el navegador lo abra.
@WebServlet(name = "ReporteServlet", urlPatterns = {"/ReporteServlet"})
public class ReporteServlet extends BaseServlet {

    private final ReporteService reporteService = new ReporteService();

    @Override
    public void processRequest(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String action = request.getParameter("action");
        if (!"reserva".equals(action)) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            response.setContentType("text/plain;charset=UTF-8");
            response.getWriter().write("Acción de reporte no soportada: " + action);
            return;
        }

        try {
            int idReserva = parseIntSafe(request.getParameter("id"));
            byte[] pdf = reporteService.generarReporteReserva(idReserva);

            response.setContentType("application/pdf");
            response.setContentLength(pdf.length);
            // inline => el navegador lo "levanta" en una pestaña en lugar de descargarlo
            response.setHeader("Content-Disposition", "inline; filename=reserva-" + idReserva + ".pdf");
            response.getOutputStream().write(pdf);
            response.getOutputStream().flush();
        } catch (IllegalArgumentException e) {
            response.setStatus(HttpServletResponse.SC_NOT_FOUND);
            response.setContentType("text/plain;charset=UTF-8");
            response.getWriter().write(e.getMessage());
        } catch (RuntimeException e) {
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            response.setContentType("text/plain;charset=UTF-8");
            response.getWriter().write("No se pudo generar el reporte: " + e.getMessage());
        }
    }
}
