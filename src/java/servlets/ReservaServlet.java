package servlets;

import java.io.IOException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import controllers.ReservaController;
import core.services.ResponseService;
import core.servlets.BaseServlet;
import models.Reserva;

@WebServlet(name = "ReservaServlet", urlPatterns = {"/ReservaServlet"})
@MultipartConfig
public class ReservaServlet extends BaseServlet {

    private final ReservaController reservaController = new ReservaController();

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
                responseService = listarReservas(request);
            case "crear" ->
                responseService = crearReserva(request);
            case "actualizar" ->
                responseService = actualizarReserva(request);
            default ->
                responseService = defaultError(action);
        }

        sendJsonResponse(response, responseService);
    }

    private ResponseService<?> listarReservas(HttpServletRequest request) {
        String buscar = request.getParameter("buscar") != null ? request.getParameter("buscar") : "";
        return reservaController.listarReservas(buscar);
    }

    private ResponseService<?> crearReserva(HttpServletRequest request) {
        Reserva reserva = new Reserva();
        reserva.setIdCliente(parseIntSafe(request.getParameter("id_cliente")));
        reserva.setIdEmpleado(parseIntSafe(request.getParameter("id_empleado")));
        reserva.setIdHabitacion(parseIntSafe(request.getParameter("id_habitacion")));
        reserva.setMontoTotal(parseDoubleSafe(request.getParameter("monto_total")));
        reserva.setFechaReserva(request.getParameter("fecha_reserva"));
        reserva.setFechaEntrada(request.getParameter("fecha_entrada"));
        reserva.setFechaSalida(request.getParameter("fecha_salida"));
        reserva.setEstado(request.getParameter("estado"));

        return reservaController.crearReserva(reserva);
    }

    private ResponseService<?> actualizarReserva(HttpServletRequest request) {
        Reserva reserva = new Reserva();
        reserva.setIdReserva(parseIntSafe(request.getParameter("id_reserva")));
        reserva.setIdHabitacion(parseIntSafe(request.getParameter("id_habitacion")));
        reserva.setIdCliente(parseIntSafe(request.getParameter("id_cliente")));
        reserva.setIdEmpleado(parseIntSafe(request.getParameter("id_empleado")));
        reserva.setTipo(request.getParameter("tipo"));
//        reserva.setTiempoReservado(request.getParameter("tiempo_reservado"));
        reserva.setMontoTotal(parseDoubleSafe(request.getParameter("monto_total")));
        reserva.setEstado(request.getParameter("estado"));
        reserva.setFechaReserva(request.getParameter("fecha_reservado"));
        reserva.setFechaEntrada(request.getParameter("fecha_entrada"));
        reserva.setFechaSalida(request.getParameter("fecha_salida"));

        return reservaController.actualizarReserva(reserva);
    }

//    private ResponseService<?> eliminarReserva(HttpServletRequest request) {
//        int idReserva = parseIntSafe(request.getParameter("id_reserva"));
//        return reservaController.eliminarReserva(idReserva);
//    }
}
