package core.servlets;

import com.google.gson.Gson;
import core.services.ResponseService;
import java.io.IOException;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import models.Usuario;

public abstract class BaseServlet extends HttpServlet {

    public Usuario usuarioAutenticado;

    public void processRequest(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        verificarSesion(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        verificarSesion(request, response);
    }

    private void verificarSesion(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String action = request.getParameter("action");

        if (action != null && !action.equalsIgnoreCase("login")) {
            HttpSession session = request.getSession(false); // no crear nueva sesión
            this.usuarioAutenticado = (session != null) ? getUsuarioAutenticado(request) : null;
            if (this.usuarioAutenticado == null) {
                response.setStatus(401);

                ResponseService<?> responseService = new ResponseService<>();

                responseService.setSuccess(false);
                responseService.setMessage("Sesión expirada");
                responseService.setCode(401); // <-- nuevo campo opcional
                responseService.setRedirectUrl(request.getContextPath() + "/login.jsp");

                String json = new Gson().toJson(responseService);
                response.setContentType("application/json;charset=UTF-8");
                response.getWriter().write(json);
                return;
            }
        }

        // Autenticado → continuar con la lógica del servlet hijo
        processRequest(request, response);
    }

    public Usuario getUsuarioAutenticado(HttpServletRequest request) {
        // Obtener sesión de usuario autenticado
        return (Usuario) request.getSession().getAttribute("usuario");
    }

    public ResponseService<?> defaultError(String action) {
        ResponseService<Object> responseService = new ResponseService<>();
        responseService.setSuccess(false);
        responseService.setMessage("Acción desconocida o no permitida: " + action);
        return responseService;
    }

    public int parseIntSafe(String value) {
        try {
            return Integer.parseInt(value);
        } catch (NumberFormatException e) {
            throw new Error("Error al parsear variable");
        }
    }

    public double parseDoubleSafe(String value) {
        try {
            return Double.parseDouble(value);
        } catch (NumberFormatException e) {
            throw new Error("Error al parsear variable");
        }
    }

    public void sendJsonResponse(HttpServletResponse response, ResponseService<?> responseService) throws IOException {
        response.setContentType("application/json;charset=UTF-8");
        String json = new Gson().toJson(responseService);
        response.getWriter().write(json);
    }
}
