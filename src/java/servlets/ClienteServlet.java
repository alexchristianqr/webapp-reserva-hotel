package servlets;

import com.google.gson.Gson;
import controllers.ClienteController;
import core.services.ResponseService;
import core.servlets.BaseServlet;
import java.io.IOException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import models.Cliente;

@WebServlet(name = "ClienteServlet", urlPatterns = {"/ClienteServlet"})
@MultipartConfig
public class ClienteServlet extends BaseServlet {

    private final ClienteController clienteController = new ClienteController();

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
                responseService = listarClientes(request);
            case "crear" ->
                responseService = crearCliente(request);
            case "actualizar" ->
                responseService = actualizarCliente(request);
            default ->
                responseService = defaultError(action);
        }

        String json = new Gson().toJson(responseService);
        response.getWriter().write(json);
    }

    private ResponseService<?> listarClientes(HttpServletRequest request) {
        String buscar = request.getParameter("buscar") != null ? request.getParameter("buscar") : "";
        return clienteController.listarClientes(buscar);
    }

    private ResponseService<?> crearCliente(HttpServletRequest request) {
        Cliente cliente = new Cliente();
        cliente.setNombre(request.getParameter("nombre"));
        cliente.setApellidos(request.getParameter("apellidos"));
        cliente.setNroDocumento(request.getParameter("nroDocumento"));
        cliente.setTipoDocumento(parseIntSafe(request.getParameter("tipoDocumento")));
        cliente.setEdad(request.getParameter("edad"));
        cliente.setSexo(request.getParameter("sexo"));
        cliente.setTelefono(request.getParameter("telefono"));
        cliente.setEstado("activo"); // Valor por defecto
        return clienteController.crearCliente(cliente);
    }

    private ResponseService<?> actualizarCliente(HttpServletRequest request) {
        Cliente cliente = new Cliente();
        cliente.setIdCliente(parseIntSafe(request.getParameter("idCliente")));
        cliente.setNombre(request.getParameter("nombre"));
        cliente.setApellidos(request.getParameter("apellidos"));
        cliente.setNroDocumento(request.getParameter("nroDocumento"));
        cliente.setTipoDocumento(parseIntSafe(request.getParameter("tipoDocumento")));
        cliente.setEdad(request.getParameter("edad"));
        cliente.setSexo(request.getParameter("sexo"));
        cliente.setTelefono(request.getParameter("telefono"));
        cliente.setEstado(request.getParameter("estado"));
        return clienteController.actualizarCliente(cliente);
    }
}
