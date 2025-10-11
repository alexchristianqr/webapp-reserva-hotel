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

    @Override
    public void processRequest(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // Acción solicitada desde el JSP
        String action = request.getParameter("action");
        if (action == null) {
            action = "listar";
        }

        HabitacionController habitacionController = new HabitacionController();
        ResponseService responseService;

        switch (action) {
            case "listar":
                // Retorna la lista de habitaciones
                String buscar = "";
                responseService = habitacionController.listarHabitaciones(buscar);
                break;

            case "crear":
                // Crear una nueva habitación
                Habitacion nuevaHabitacion = new Habitacion();
                nuevaHabitacion.setIdTipoHabitacion(1);
                nuevaHabitacion.setNumeroPiso(request.getParameter("numero"));
                nuevaHabitacion.setPrecio(Double.parseDouble(request.getParameter("precio")));
                nuevaHabitacion.setEstado(request.getParameter("estado"));

                responseService = habitacionController.crearHabitacion(nuevaHabitacion);
                break;

            case "actualizar":
                // Actualizar una habitación existente
                Habitacion habitacionActualizada = new Habitacion();
                habitacionActualizada.setIdHabitacion(Integer.parseInt(request.getParameter("idHabitacion")));
                habitacionActualizada.setIdHabitacion(1);
                habitacionActualizada.setNumeroPiso(request.getParameter("numero"));
                habitacionActualizada.setPrecio(Double.parseDouble(request.getParameter("precio")));
                habitacionActualizada.setEstado(request.getParameter("estado"));

                responseService = habitacionController.actualizarHabitacion(habitacionActualizada);
                break;

            default:
                // Acción no reconocida
                responseService = new ResponseService<>();
                responseService.setSuccess(false);
                responseService.setMessage("Acción desconocida: " + action);
                break;
        }

        // Convertir la respuesta a JSON
        String json = new Gson().toJson(responseService);
        response.setContentType("application/json;charset=UTF-8");
        response.getWriter().write(json);
    }
}
