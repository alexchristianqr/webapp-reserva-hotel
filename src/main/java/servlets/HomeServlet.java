package servlets;

import java.io.IOException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import core.services.ResponseService;
import core.servlets.BaseServlet;

@WebServlet(name = "HomeServlet", urlPatterns = {"/HomeServlet"})
@MultipartConfig // Añadir esta línea para usar FormData
public class HomeServlet extends BaseServlet {

    @Override
    public void processRequest(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        ResponseService responseService = new ResponseService();
        responseService.setSuccess(true);
        responseService.setMessage("Usuario en sesion");

        // Obtener sesión de usuario
        responseService.setResult(getUsuarioAutenticado(request));

        sendJsonResponse(response, responseService);
    }
}
