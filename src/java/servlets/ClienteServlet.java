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

// La URL base para todas las operaciones de clientes.
@WebServlet(name = "ClienteServlet", urlPatterns = {"/clientes"})
@MultipartConfig
public class ClienteServlet extends BaseServlet {

    @Override
    public void processRequest(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // Leemos el parámetro "action" para saber qué hacer.
        String action = request.getParameter("action");
        if (action == null) {
            action = "listar"; // Si no se especifica, la acción por defecto es listar.
        }

        ClienteController clienteController = new ClienteController();
        ResponseService responseService; // Usamos tu clase de respuesta estándar.

        // Usamos un switch para manejar las diferentes acciones.
        switch (action) {
            case "listar":
                String buscar = "";
                // Llama al método del controlador que ya refactorizamos.
                responseService = clienteController.listarClientes(buscar);
                break;

            case "crear":
                // Creamos un objeto Cliente con los datos que vienen del formulario.
                Cliente nuevoCliente = new Cliente();
                nuevoCliente.setNombre(request.getParameter("nombre"));
                nuevoCliente.setApellidos(request.getParameter("apellidos"));
                nuevoCliente.setNroDocumento(request.getParameter("nroDocumento"));
                nuevoCliente.setTipoDocumento(Integer.parseInt(request.getParameter("tipoDocumento")));
                nuevoCliente.setEdad(request.getParameter("edad"));
                nuevoCliente.setSexo(request.getParameter("sexo"));
                nuevoCliente.setTelefono(request.getParameter("telefono"));
                nuevoCliente.setEstado("activo"); // Estado por defecto al crear
                
                responseService = clienteController.crearCliente(nuevoCliente);
                break;

            case "actualizar":
                Cliente clienteActualizado = new Cliente();
                // OJO: Necesitamos el ID para saber a quién actualizar.
                clienteActualizado.setIdCliente(Integer.parseInt(request.getParameter("idCliente")));
                clienteActualizado.setNombre(request.getParameter("nombre"));
                clienteActualizado.setApellidos(request.getParameter("apellidos"));
                clienteActualizado.setNroDocumento(request.getParameter("nroDocumento"));
                clienteActualizado.setTipoDocumento(Integer.parseInt(request.getParameter("tipoDocumento")));
                clienteActualizado.setEdad(request.getParameter("edad"));
                clienteActualizado.setSexo(request.getParameter("sexo"));
                clienteActualizado.setTelefono(request.getParameter("telefono"));
                clienteActualizado.setEstado(request.getParameter("estado"));

                responseService = clienteController.actualizarCliente(clienteActualizado);
                break;

            default:
                // Si la acción no es reconocida, devolvemos un error.
                responseService = new ResponseService<>();
                responseService.setSuccess(false);
                responseService.setMessage("Acción desconocida: " + action);
                break;
        }

        // Convertimos la respuesta a JSON y la enviamos al frontend.
        String json = new Gson().toJson(responseService);
        response.getWriter().write(json);
    }
}