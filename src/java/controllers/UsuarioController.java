package controllers;

import core.services.ResponseService;
import models.Usuario;
import services.AuthService;
import services.UsuarioService;

public class UsuarioController extends BaseController<Usuario, UsuarioService> {

    private final AuthService authService;
    private final UsuarioService usuarioService;

    public UsuarioController() {
        usuarioService = new UsuarioService();
        authService = new AuthService();
    }

    public ResponseService<Usuario> login(String username, String pwd) {
        ResponseService<Usuario> response = new ResponseService<>();
        Usuario usuario = authService.login(username, pwd);

        if (usuario == null) {
            response.setSuccess(false);
            response.setMessage("Credenciales inválidas");
        } else {
            response.setSuccess(true);
            response.setMessage("usuario logueado como: " + usuario.getRol());
            response.setResult(usuario);
        }

        return response;
    }

    public ResponseService<Boolean> registrarUsuario(Usuario usuario) {
        ResponseService<Boolean> response = new ResponseService<>();
        Boolean success = usuarioService.registrarUsuario(usuario);

        if (!success) {
            response.setSuccess(false);
            response.setMessage("Error al registrar");
        } else {
            response.setSuccess(true);
            response.setMessage("Registrado correctamente");

        }

        return response;
    }

    public ResponseService<Boolean> logout() {
        ResponseService<Boolean> response = new ResponseService<>();
        Boolean success = authService.logout();

        if (!success) {
            response.setSuccess(false);
            response.setMessage("Error al cerrar sesión");
        } else {
            response.setSuccess(true);
            response.setMessage("Procesado correctamente");
        }

        return response;
    }
}
