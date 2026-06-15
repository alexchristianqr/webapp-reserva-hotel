package servlets;

import controllers.ComprobanteController;
import core.services.ResponseService;
import core.servlets.BaseServlet;
import java.io.IOException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@WebServlet(name = "ComprobanteServlet", urlPatterns = {"/ComprobanteServlet"})
@MultipartConfig
public class ComprobanteServlet extends BaseServlet {

    private final ComprobanteController comprobanteController = new ComprobanteController();

    @Override
    public void processRequest(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String action = request.getParameter("action");
        if (action == null) {
            action = "listar";
        }

        ResponseService<?> responseService;

        switch (action) {
            case "listar" ->
                responseService = comprobanteController.listarComprobantes(parseIntSafe(request.getParameter("id_reserva")));
            case "crear" ->
                responseService = comprobanteController.generarComprobante(
                        parseIntSafe(request.getParameter("id_reserva")),
                        empleadoEnSesion(),
                        parseIntSafe(request.getParameter("tipo_comprobante")));
            default ->
                responseService = defaultError(action);
        }

        sendJsonResponse(response, responseService);
    }

    // El comprobante lo emite el empleado autenticado (no se confía al navegador).
    private int empleadoEnSesion() {
        return usuarioAutenticado != null ? usuarioAutenticado.getIdEmpleado() : 0;
    }
}
