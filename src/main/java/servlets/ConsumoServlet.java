package servlets;

import controllers.ReservaConsumoController;
import core.services.ResponseService;
import core.servlets.BaseServlet;
import java.io.IOException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@WebServlet(name = "ConsumoServlet", urlPatterns = {"/ConsumoServlet"})
@MultipartConfig
public class ConsumoServlet extends BaseServlet {

    private final ReservaConsumoController consumoController = new ReservaConsumoController();

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
                responseService = consumoController.listarConsumos(parseIntSafe(request.getParameter("id_reserva")));
            case "crear" ->
                responseService = consumoController.agregarConsumo(
                        parseIntSafe(request.getParameter("id_reserva")),
                        parseIntSafe(request.getParameter("id_producto")),
                        parseIntSafe(request.getParameter("cantidad")));
            case "eliminar" ->
                responseService = consumoController.eliminarConsumo(parseIntSafe(request.getParameter("id_consumo")));
            default ->
                responseService = defaultError(action);
        }

        sendJsonResponse(response, responseService);
    }
}
