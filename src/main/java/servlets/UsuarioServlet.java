package servlets;

import controllers.UsuarioController;
import core.services.ResponseService;
import core.servlets.BaseServlet;
import java.io.IOException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import models.Usuario;

@WebServlet(name = "UsuarioServlet", urlPatterns = {"/UsuarioServlet"})
@MultipartConfig
public class UsuarioServlet extends BaseServlet {

    private final UsuarioController usuarioController = new UsuarioController();

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
                responseService = listarUsuarios(request);
            case "crear" ->
                responseService = crearUsuario(request);
            case "actualizar" ->
                responseService = actualizarUsuario(request);
            case "eliminar" ->
                responseService = eliminarUsuario(request);
            default ->
                responseService = defaultError(action);
        }

        sendJsonResponse(response, responseService);
    }

    private ResponseService<?> listarUsuarios(HttpServletRequest request) {
        String buscar = request.getParameter("buscar") != null ? request.getParameter("buscar") : "";
        return usuarioController.listarUsuarios(buscar);
    }

    private ResponseService<?> crearUsuario(HttpServletRequest request) {
        Usuario usuario = new Usuario();
        usuario.setNombres(request.getParameter("nombres"));
        usuario.setApellidos(request.getParameter("apellidos"));
        usuario.setRol(request.getParameter("rol"));
        usuario.setUsername(request.getParameter("username"));
        usuario.setPassword(request.getParameter("password"));
        usuario.setEstado("activo"); // Valor por defecto
        return usuarioController.registrarUsuario(usuario);
    }

    private ResponseService<?> actualizarUsuario(HttpServletRequest request) {
        Usuario usuario = new Usuario();
        usuario.setIdUsuario(parseIntSafe(request.getParameter("idUsuario")));
        usuario.setNombres(request.getParameter("nombres"));
        usuario.setApellidos(request.getParameter("apellidos"));
        usuario.setRol(request.getParameter("rol"));
        usuario.setUsername(request.getParameter("username"));
        usuario.setEstado(request.getParameter("estado"));
        usuario.setPassword(request.getParameter("password")); // opcional: solo si se quiere cambiar
        return usuarioController.actualizarUsuario(usuario);
    }

    private ResponseService<?> eliminarUsuario(HttpServletRequest request) {
        Usuario usuario = new Usuario();
        usuario.setIdUsuario(parseIntSafe(request.getParameter("idUsuario")));
        return usuarioController.eliminarUsuario(usuario);
    }
}
