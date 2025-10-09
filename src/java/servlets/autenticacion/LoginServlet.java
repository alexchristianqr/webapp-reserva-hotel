package servlets.autenticacion;

import java.io.IOException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
//import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import com.google.gson.Gson;
import controllers.UsuarioController;
import core.services.ResponseService;
import core.servlets.BaseServlet;

@WebServlet(name = "LoginServlet", urlPatterns = {"/auth/LoginServlet"})
@MultipartConfig // Añadir esta línea para usar FormData
public class LoginServlet extends BaseServlet {

    @Override
    public void processRequest(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String username = request.getParameter("username");
        String password = request.getParameter("password");

        // Simular una lista de usuarios (o la obtienes de una DB)
        UsuarioController usuarioController = new UsuarioController();
        ResponseService responseService = usuarioController.login(username, password);

        // Convertir la lista a JSON
        String json = new Gson().toJson(responseService);

        // Enviar el JSON como respuesta
        response.getWriter().write(json);
    }
}
