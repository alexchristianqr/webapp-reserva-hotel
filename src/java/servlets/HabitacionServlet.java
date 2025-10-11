package servlets;

import com.google.gson.Gson;
import controllers.HabitacionController;
import core.services.ResponseService;
import core.servlets.BaseServlet;
import java.io.IOException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import models.Habitacion;

@WebServlet(name = "HabitacionServlet", urlPatterns = {"/HabitacionServlet"})
@MultipartConfig
public class HabitacionServlet extends BaseServlet {

    private final HabitacionController habitacionController = new HabitacionController();

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
                responseService = listarHabitaciones(request);
            case "crear" ->
                responseService = crearHabitacion(request);
            case "actualizar" ->
                responseService = actualizarHabitacion(request);
            default ->
                responseService = defaultError(action);
        }

        sendJsonResponse(response, responseService);
    }

    private ResponseService<?> listarHabitaciones(HttpServletRequest request) {
        String buscar = request.getParameter("buscar") != null ? request.getParameter("buscar") : "";
        return habitacionController.listarHabitaciones(buscar);
    }

    private ResponseService<?> crearHabitacion(HttpServletRequest request) {
        Habitacion habitacion = new Habitacion();
        habitacion.setIdTipoHabitacion(parseIntSafe(request.getParameter("idTipoHabitacion"))); // valor por defecto 1
        habitacion.setNumeroPiso(request.getParameter("numero"));
        habitacion.setPrecio(parseDoubleSafe(request.getParameter("precio")));
        habitacion.setEstado(request.getParameter("estado"));
        return habitacionController.crearHabitacion(habitacion);
    }

    private ResponseService<?> actualizarHabitacion(HttpServletRequest request) {
        Habitacion habitacion = new Habitacion();
        habitacion.setIdHabitacion(parseIntSafe(request.getParameter("idHabitacion")));
        habitacion.setIdTipoHabitacion(parseIntSafe(request.getParameter("idTipoHabitacion")));
        habitacion.setNumeroPiso(request.getParameter("numero"));
        habitacion.setPrecio(parseDoubleSafe(request.getParameter("precio")));
        habitacion.setEstado(request.getParameter("estado"));
        return habitacionController.actualizarHabitacion(habitacion);
    }
}
