package servlets;

import controllers.EmpleadoController;
import core.services.ResponseService;
import core.servlets.BaseServlet;
import java.io.IOException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import models.Empleado;

@WebServlet(name = "EmpleadoServlet", urlPatterns = {"/EmpleadoServlet"})
@MultipartConfig
public class EmpleadoServlet extends BaseServlet {

    private final EmpleadoController empleadoController = new EmpleadoController();

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
                responseService = listarEmpleados(request);
            case "crear" ->
                responseService = crearEmpleado(request);
            case "actualizar" ->
                responseService = actualizarEmpleado(request);
            case "eliminar" ->
                responseService = eliminarEmpleado(request);
            default ->
                responseService = defaultError(action);
        }

        sendJsonResponse(response, responseService);
    }

    private ResponseService<?> listarEmpleados(HttpServletRequest request) {
        String buscar = request.getParameter("buscar") != null ? request.getParameter("buscar") : "";
        return empleadoController.listarEmpleados(buscar);
    }

    private ResponseService<?> crearEmpleado(HttpServletRequest request) {
        Empleado empleado = new Empleado();
        empleado.setNombre(request.getParameter("nombre"));
        empleado.setApellidos(request.getParameter("apellidos"));
        empleado.setTipoDocumento(parseIntSafe(request.getParameter("tipoDocumento")));
        empleado.setNroDocumento(request.getParameter("nroDocumento"));
        empleado.setEdad(request.getParameter("edad"));
        empleado.setSexo(request.getParameter("sexo"));
        empleado.setTelefono(request.getParameter("telefono"));
        empleado.setIdPerfil(parseIntSafe(request.getParameter("idPerfil")));
        empleado.setSueldo(parseDoubleSafe(request.getParameter("sueldo")));
        empleado.setUsername(request.getParameter("username"));
        empleado.setPassword(request.getParameter("password"));
        empleado.setEstado("activo"); // Valor por defecto
        return empleadoController.crearEmpleado(empleado);
    }

    private ResponseService<?> actualizarEmpleado(HttpServletRequest request) {
        Empleado empleado = new Empleado();
        empleado.setIdEmpleado(parseIntSafe(request.getParameter("idEmpleado")));
        empleado.setNombre(request.getParameter("nombre"));
        empleado.setApellidos(request.getParameter("apellidos"));
        empleado.setTipoDocumento(parseIntSafe(request.getParameter("tipoDocumento")));
        empleado.setNroDocumento(request.getParameter("nroDocumento"));
        empleado.setEdad(request.getParameter("edad"));
        empleado.setSexo(request.getParameter("sexo"));
        empleado.setTelefono(request.getParameter("telefono"));
        empleado.setIdPerfil(parseIntSafe(request.getParameter("idPerfil")));
        empleado.setSueldo(parseDoubleSafe(request.getParameter("sueldo")));
        empleado.setEstado(request.getParameter("estado"));
        return empleadoController.actualizarEmpleado(empleado);
    }

    private ResponseService<?> eliminarEmpleado(HttpServletRequest request) {
        Empleado empleado = new Empleado();
        empleado.setIdEmpleado(parseIntSafe(request.getParameter("idEmpleado")));
        return empleadoController.eliminarEmpleado(empleado);
    }
}
