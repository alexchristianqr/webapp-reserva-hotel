package servlets;

import java.io.IOException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.util.ArrayList;
import java.util.List;
import com.google.gson.Gson;
import models.Prueba;

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
        List<Prueba> usuarios = new ArrayList<>();
        Prueba usuario = new Prueba(username, password);
        if ("admin".equals(username) && "123".equals(password)) {
            usuarios.add(usuario);
//            usuarios.add(new Prueba("Ana", "ana@ejemplo.com"));
        }

        // Convertir la lista a JSON
        String json = new Gson().toJson(usuarios);

        // Enviar el JSON como respuesta
        response.getWriter().write(json);
    }

}
