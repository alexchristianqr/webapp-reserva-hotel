package controllers;

import core.BaseController;
import core.services.ResponseService;
import java.util.List;
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

    public ResponseService<List<Usuario>> listarUsuarios(String buscar) {
        ResponseService<List<Usuario>> response = new ResponseService<>();
        List<Usuario> usuarios = usuarioService.listarUsuarios(buscar);

        if (usuarios.isEmpty()) {
            response.setSuccess(false);
            response.setMessage("No hay nada que listar");
        } else {
            response.setSuccess(true);
            response.setMessage("Procesado correctamente");
            response.setResult(usuarios);
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

    public ResponseService<Boolean> actualizarUsuario(Usuario usuario) {
        ResponseService<Boolean> response = new ResponseService<>();
        Boolean success = usuarioService.actualizarUsuario(usuario);

        if (!success) {
            response.setSuccess(false);
            response.setMessage("Error al actualizar");
        } else {
            response.setSuccess(true);
            response.setMessage("Actualizado correctamente");
        }

        return response;
    }

    public ResponseService<Boolean> eliminarUsuario(Usuario usuario) {
        ResponseService<Boolean> response = new ResponseService<>();
        Boolean success = usuarioService.eliminarUsuario(usuario);

        if (!success) {
            response.setSuccess(false);
            response.setMessage("Error al eliminar");
        } else {
            response.setSuccess(true);
            response.setMessage("Eliminado correctamente");
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
