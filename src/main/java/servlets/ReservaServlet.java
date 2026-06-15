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
            case "disponibilidad" ->
                responseService = listarHabitacionesDisponibles(request);
            case "crear" ->
                responseService = crearReserva(request);
            case "actualizar" ->
                responseService = actualizarReserva(request);
            case "eliminar" ->
                responseService = cancelarReserva(request);
            default ->
                responseService = defaultError(action);
        }

        sendJsonResponse(response, responseService);
    }

    private ResponseService<?> listarReservas(HttpServletRequest request) {
        String buscar = request.getParameter("buscar") != null ? request.getParameter("buscar") : "";
        return reservaController.listarReservas(buscar);
    }

    // GET ?action=disponibilidad&fecha_entrada=YYYY-MM-DD&fecha_salida=YYYY-MM-DD[&id_reserva=N]
    private ResponseService<?> listarHabitacionesDisponibles(HttpServletRequest request) {
        String fechaEntrada = request.getParameter("fecha_entrada");
        String fechaSalida = request.getParameter("fecha_salida");
        int idReservaExcluir = parseIntOrDefault(request.getParameter("id_reserva"), 0);

        return reservaController.listarHabitacionesDisponibles(fechaEntrada, fechaSalida, idReservaExcluir);
    }

    private ResponseService<?> crearReserva(HttpServletRequest request) {
        Reserva reserva = new Reserva();
        reserva.setIdCliente(parseIntSafe(request.getParameter("id_cliente")));
        reserva.setIdEmpleado(empleadoEnSesion(request.getParameter("id_empleado")));
        reserva.setIdHabitacion(parseIntSafe(request.getParameter("id_habitacion")));
        reserva.setCantidadHuespedes(parseIntOrDefault(request.getParameter("cantidad_huespedes"), 1));
        reserva.setFechaEntrada(request.getParameter("fecha_entrada"));
        reserva.setFechaSalida(request.getParameter("fecha_salida"));
        reserva.setEstado(request.getParameter("estado"));
        // monto_total y numero_noches se calculan en el servidor (ReservaService)

        return reservaController.crearReserva(reserva);
    }

    private ResponseService<?> actualizarReserva(HttpServletRequest request) {
        Reserva reserva = new Reserva();
        reserva.setIdReserva(parseIntSafe(request.getParameter("id_reserva")));
        reserva.setIdHabitacion(parseIntSafe(request.getParameter("id_habitacion")));
        reserva.setIdCliente(parseIntSafe(request.getParameter("id_cliente")));
        reserva.setIdEmpleado(empleadoEnSesion(request.getParameter("id_empleado")));
        reserva.setCantidadHuespedes(parseIntOrDefault(request.getParameter("cantidad_huespedes"), 1));
        reserva.setEstado(request.getParameter("estado"));
        reserva.setFechaEntrada(request.getParameter("fecha_entrada"));
        reserva.setFechaSalida(request.getParameter("fecha_salida"));

        return reservaController.actualizarReserva(reserva);
    }

    private ResponseService<?> cancelarReserva(HttpServletRequest request) {
        int idReserva = parseIntSafe(request.getParameter("id"));
        return reservaController.cancelarReserva(idReserva);
    }

    private int parseIntOrDefault(String value, int porDefecto) {
        if (value == null || value.isBlank()) {
            return porDefecto;
        }
        return parseIntSafe(value);
    }

    // La reserva queda a nombre del empleado autenticado; si no hubiera sesión válida
    // (caso improbable), se respeta el valor recibido del formulario.
    private int empleadoEnSesion(String valorFormulario) {
        if (usuarioAutenticado != null && usuarioAutenticado.getIdEmpleado() > 0) {
            return usuarioAutenticado.getIdEmpleado();
        }
        return parseIntOrDefault(valorFormulario, 1);
    }
}
