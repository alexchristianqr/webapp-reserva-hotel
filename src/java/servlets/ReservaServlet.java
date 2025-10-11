package servlets;

import java.io.IOException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import com.google.gson.Gson;
import controllers.ReservaController;
import core.services.ResponseService;
import core.servlets.BaseServlet;

@WebServlet(name = "ReservaServlet", urlPatterns = {"/ReservaServlet"})
@MultipartConfig // Añadir esta línea para usar FormData
public class ReservaServlet extends BaseServlet {

    @Override
    public void processRequest(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String action = request.getParameter("action");

        switch (action) {
            case "crear" ->
                crearReserva(request, response);
            case "actualizar" ->
                actualizarReserva(request, response);
            case "eliminar" ->
                eliminarReserva(request, response);
            case "listar" ->
                listarReservas(request, response);
            default ->
                defaultError(request, response);
        }
    }

    private void defaultError(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        String action = request.getParameter("action");

        // Si la acción no es reconocida, devolvemos un error.
        ResponseService responseService = new ResponseService<>();
        responseService.setSuccess(false);
        responseService.setMessage("Acción desconocida: " + action);

        // Convertimos la respuesta a JSON y la enviamos al frontend.
        String json = new Gson().toJson(responseService);
        response.getWriter().write(json);
    }

    private void listarReservas(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // Simular una lista de usuarios (o la obtienes de una DB)
        ReservaController reservaController = new ReservaController();
        ResponseService responseService = reservaController.listarReservas("");

        // Convertir la lista a JSON
        String json = new Gson().toJson(responseService);

        // Enviar el JSON como respuesta
        response.getWriter().write(json);
    }

    private void crearReserva(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
//        Reserva reserva = new Reserva();
//
//        reservaService.guardar(reserva);
//        response.sendRedirect("ReservaServlet");
    }

    private void actualizarReserva(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
//        int id = Integer.parseInt(request.getParameter("id"));
//        Reserva reserva = reservaService.buscarPorId(id);
//        reserva.setCliente(request.getParameter("cliente"));
//        reserva.setHabitacion(request.getParameter("habitacion"));
//        reserva.setFechaEntrada(request.getParameter("fechaEntrada"));
//        reserva.setFechaSalida(request.getParameter("fechaSalida"));
//
//        reservaService.actualizar(reserva);
//        response.sendRedirect("ReservaServlet");
    }

    private void eliminarReserva(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
//        int id = Integer.parseInt(request.getParameter("id"));
//        reservaService.eliminar(id);
//        response.sendRedirect("ReservaServlet");
    }
}
