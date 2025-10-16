package servlets;

import java.io.IOException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import controllers.UsuarioController;
import core.services.ResponseService;
import core.servlets.BaseServlet;
import jakarta.servlet.http.HttpSession;
import models.Usuario;

@WebServlet(name = "AutenticacionServlet", urlPatterns = {"/AutenticacionServlet"})
@MultipartConfig
public class AutenticacionServlet extends BaseServlet {

    private final UsuarioController usuarioController = new UsuarioController();

    @Override
    public void processRequest(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String action = request.getParameter("action");
        if (action == null) {
            action = "login";
        }

        ResponseService<?> responseService;

        switch (action) {
            case "login" ->
                responseService = handleLogin(request);
            case "logout" ->
                responseService = handleLogout(request);
            default ->
                responseService = defaultError(action);
        }

        sendJsonResponse(response, responseService);
    }

    private ResponseService<?> handleLogin(HttpServletRequest request) {
        String username = request.getParameter("username");
        String password = request.getParameter("password");

        ResponseService<?> responseService = usuarioController.login(username, password);

        // Si el login es exitoso, guardar usuario en sesión
        if (responseService.isSuccess() && responseService.getResult() instanceof Usuario usuario) {
            request.getSession().setAttribute("usuario", responseService.getResult());
//            usuarioAutenticado = usuario;
        }

        return responseService;
    }

    private ResponseService<?> handleLogout(HttpServletRequest request) {
        // Invalidar sesión activa
        HttpSession session = request.getSession(false);
        if (session != null) {
            session.invalidate();
        }

        return usuarioController.logout();
    }
}
