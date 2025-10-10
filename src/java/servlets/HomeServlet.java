package servlets;

import java.io.IOException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import com.google.gson.Gson;
import core.services.ResponseService;
//import controllers.UsuarioController;
//import core.services.ResponseService;
import core.servlets.BaseServlet;
import models.Usuario;

@WebServlet(name = "HomeServlet", urlPatterns = {"/HomeServlet"})
@MultipartConfig // Añadir esta línea para usar FormData
public class HomeServlet extends BaseServlet {

    @Override
    public void processRequest(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // Obtener sesión de usuario
        Usuario usuarioAutenticado = getUsuarioAutenticado(request);

        ResponseService responseService = new ResponseService();
        responseService.setSuccess(true);
        responseService.setMessage("Usuario en sesion");
        responseService.setResult(usuarioAutenticado);

        // Convertir la lista a JSON
        String json = new Gson().toJson(responseService);

        // Enviar el JSON como respuesta
        response.getWriter().write(json);
    }
}
