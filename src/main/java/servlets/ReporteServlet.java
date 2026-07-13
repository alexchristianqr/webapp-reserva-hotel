package servlets;

import controllers.ReporteNegocioController;
import core.servlets.BaseServlet;
import java.io.IOException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import services.ReporteNegocioService;
import services.ReporteService;

// Sirve reportes. Algunas acciones responden JSON (como el resto de servlets) y otras
// escriben binario directamente (PDF de reserva, Excel de negocio) para que el navegador
// lo abra o lo descargue.
@WebServlet(name = "ReporteServlet", urlPatterns = {"/ReporteServlet"})
public class ReporteServlet extends BaseServlet {

    private final ReporteService reporteService = new ReporteService();
    private final ReporteNegocioController reporteNegocioController = new ReporteNegocioController();
    private final ReporteNegocioService reporteNegocioService = new ReporteNegocioService();

    @Override
    public void processRequest(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String action = request.getParameter("action");
        if (action == null) {
            action = "";
        }

        switch (action) {
            case "reserva" -> reportePdfReserva(request, response);
            case "dashboard" -> dashboardNegocio(request, response);
            case "excel" -> excelNegocio(request, response);
            default -> {
                response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                response.setContentType("text/plain;charset=UTF-8");
                response.getWriter().write("Acción de reporte no soportada: " + action);
            }
        }
    }

    // PDF de una reserva individual (se abre inline en el navegador).
    private void reportePdfReserva(HttpServletRequest request, HttpServletResponse response) throws IOException {
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

    // Datos agregados del panel de reportes (KPIs + series para los gráficos), en JSON.
    private void dashboardNegocio(HttpServletRequest request, HttpServletResponse response) throws IOException {
        String desde = request.getParameter("desde");
        String hasta = request.getParameter("hasta");
        sendJsonResponse(response, reporteNegocioController.obtenerDashboard(desde, hasta));
    }

    // Reporte de negocio descargable en Excel (.xlsx).
    private void excelNegocio(HttpServletRequest request, HttpServletResponse response) throws IOException {
        try {
            String desde = request.getParameter("desde");
            String hasta = request.getParameter("hasta");
            byte[] xlsx = reporteNegocioService.generarExcel(desde, hasta);

            String nombre = "reporte-negocio.xlsx";
            response.setContentType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
            response.setContentLength(xlsx.length);
            response.setHeader("Content-Disposition", "attachment; filename=" + nombre);
            response.getOutputStream().write(xlsx);
            response.getOutputStream().flush();
        } catch (RuntimeException e) {
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            response.setContentType("text/plain;charset=UTF-8");
            response.getWriter().write("No se pudo generar el Excel: " + e.getMessage());
        }
    }
}
