package servlets;

import java.io.IOException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import com.google.gson.Gson;
import controllers.UsuarioController;
import core.services.ResponseService;
import core.servlets.BaseServlet;
import models.Usuario;

@WebServlet(name = "AutenticacionServlet", urlPatterns = {"/AutenticacionServlet"})
@MultipartConfig // Añadir esta línea para usar FormData
public class AutenticacionServlet extends BaseServlet {

    @Override
    public void processRequest(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String action = request.getParameter("action");

        switch (action) {
            case "login" ->
                login(request, response);
            case "logout" ->
                logout(request, response);
            default ->
                defaultError(request, response);
        }
    }

    private void defaultError(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        String action = request.getParameter("action");

        ResponseService responseService = new ResponseService<>();
        responseService.setSuccess(false);
        responseService.setMessage("Acción desconocida: " + action);

        String json = new Gson().toJson(responseService);
        response.getWriter().write(json);
    }

    private void login(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String username = request.getParameter("username");
        String password = request.getParameter("password");

        UsuarioController usuarioController = new UsuarioController();
        ResponseService responseService = usuarioController.login(username, password);

        // Guardar sesión de usuario
        request.getSession().setAttribute("usuario", (Usuario) responseService.getResult());

        String json = new Gson().toJson(responseService);
        response.getWriter().write(json);
    }

    private void logout(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        UsuarioController usuarioController = new UsuarioController();
        ResponseService responseService = usuarioController.logout();

        String json = new Gson().toJson(responseService);
        response.getWriter().write(json);
    }
}
