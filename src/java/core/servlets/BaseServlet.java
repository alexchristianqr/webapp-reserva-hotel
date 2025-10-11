package core.servlets;

import java.io.IOException;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import models.Usuario;

public abstract class BaseServlet extends HttpServlet {

    public Usuario usuarioAutenticado;

    public void processRequest(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        processRequest(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        processRequest(request, response);
    }

    public Usuario getUsuarioAutenticado(HttpServletRequest request) {
        // Obtener sesión de usuario autenticado
        Usuario usuarioAutenticado = (Usuario) request.getSession().getAttribute("usuario");

        return usuarioAutenticado;
    }
}
