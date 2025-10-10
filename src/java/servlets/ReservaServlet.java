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
import models.Usuario;

@WebServlet(name = "ReservaServlet", urlPatterns = {"/ReservaServlet"})
@MultipartConfig // Añadir esta línea para usar FormData
public class ReservaServlet extends BaseServlet {

    @Override
    public void processRequest(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String action = request.getParameter("action");

        switch (action) {
            case "create" -> crearReserva(request, response);
            case "update" -> actualizarReserva(request, response);
            case "delete" -> eliminarReserva(request, response);
            default -> listarReservas(request, response);
        }
    }

    private void listarReservas(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

//         reserva.setCliente(request.getParameter("cliente"));
//        reserva.setHabitacion(request.getParameter("habitacion"));
//        reserva.setFechaEntrada(request.getParameter("fechaEntrada"));
//        reserva.setFechaSalida(request.getParameter("fechaSalida"));
//        String buscar = request.getParameter("buscar");

        // Simular una lista de usuarios (o la obtienes de una DB)
        ReservaController reservaController = new ReservaController();
        ResponseService responseService = reservaController.listarReservas("");

        // Guardar sesión de usuario
//        request.getSession().setAttribute("usuario", (Usuario) responseService.getResult());

        // Convertir la lista a JSON
        String json = new Gson().toJson(responseService);

        // Enviar el JSON como respuesta
        response.getWriter().write(json);

//        List<Reserva> reservas = reservaService.listar();
//        request.setAttribute("reservas", reservas);
//        request.getRequestDispatcher("views/reservas.jsp").forward(request, response);
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
