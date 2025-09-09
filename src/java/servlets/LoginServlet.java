package servlets;

import java.io.IOException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import com.google.gson.Gson;
import controllers.UsuarioController;
import core.services.ResponseService;

@WebServlet(name = "LoginServlet", urlPatterns = {"/auth/LoginServlet"})
@MultipartConfig // Añadir esta línea para usar FormData
public class LoginServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

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
