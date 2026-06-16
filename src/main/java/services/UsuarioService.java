package services;

import core.BaseService;
import core.services.MysqlDBService;
import core.utils.PasswordUtil;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import models.Cliente;
import models.Empleado;
import models.Usuario;

public class UsuarioService extends BaseService {

    public UsuarioService() {
        db = new MysqlDBService();
    }

    public List<Usuario> listarUsuarios(String buscar) {
        List<Usuario> usuarios = new ArrayList<>();

        querySQL_1 = "SELECT id, nombres, apellidos, rol, username, estado, fecha_creado, fecha_actualizado FROM usuarios";
        Object[] parametrosSQL_1 = {};

        // Búsqueda parametrizada (SQL LIKE) por nombres, apellidos o username
        if (buscar != null && !buscar.isBlank()) {
            querySQL_1 += " WHERE nombres LIKE ? OR apellidos LIKE ? OR username LIKE ?";
            String like = "%" + buscar.trim() + "%";
            parametrosSQL_1 = new Object[]{like, like, like};
        }

        querySQL_1 += " ORDER BY id DESC";
        ResultSet rs = db.queryConsultar(querySQL_1, parametrosSQL_1);

        try {
            while (rs.next()) {
                Usuario usuario = new Usuario();
                usuario.setIdUsuario(rs.getInt("id"));
                usuario.setNombres(rs.getString("nombres"));
                usuario.setApellidos(rs.getString("apellidos"));
                usuario.setRol(rs.getString("rol"));
                usuario.setUsername(rs.getString("username"));
                usuario.setEstado(rs.getString("estado"));
                usuario.setFechaCreado(rs.getString("fecha_creado"));
                usuario.setFechaActualizado(rs.getString("fecha_actualizado"));

                usuarios.add(usuario);
            }

            return usuarios;
        } catch (SQLException ex) {
            throw new RuntimeException(ex);
        } finally {
            db.cerrarConsulta();
        }
    }

    // Registra un usuario desde la pantalla de Usuarios. Delega en el servicio de la
    // entidad correspondiente (Cliente/Empleado), que crea la cadena completa
    // usuario -> persona -> cliente/empleado en una sola transacción.
    public boolean registrarUsuario(Usuario usuario) {
        if (usuario == null || usuario.getNombres() == null || usuario.getApellidos() == null
                || usuario.getRol() == null || usuario.getUsername() == null || usuario.getPassword() == null) {
            throw new IllegalArgumentException("Datos del usuario incompletos o nulos.");
        }

        String rol = usuario.getRol();

        switch (rol) {
            case "cliente" -> {
                Cliente cliente = new Cliente();
                cliente.setNombre(usuario.getNombres());
                cliente.setApellidos(usuario.getApellidos());
                cliente.setUsername(usuario.getUsername());
                cliente.setPassword(usuario.getPassword());
                cliente.setEstado("activo");
                return new ClienteService().crearCliente(cliente);
            }
            case "empleado", "admin" -> {
                Empleado empleado = new Empleado();
                empleado.setNombre(usuario.getNombres());
                empleado.setApellidos(usuario.getApellidos());
                empleado.setUsername(usuario.getUsername());
                empleado.setPassword(usuario.getPassword());
                empleado.setIdPerfil(2); // Recepcionista por defecto
                empleado.setSueldo(0);
                empleado.setEstado("activo");
                return new EmpleadoService().crearEmpleado(empleado);
            }
            default -> throw new IllegalArgumentException("Rol no permitido: " + rol);
        }
    }

    // Actualiza los datos de la cuenta de usuario. La contraseña solo se modifica
    // si se envía una nueva (campo opcional); en ese caso se guarda hasheada con bcrypt.
    public Boolean actualizarUsuario(Usuario usuario) {
        boolean cambiaPassword = usuario.getPassword() != null && !usuario.getPassword().isBlank();

        if (cambiaPassword) {
            querySQL_1 = "UPDATE usuarios SET nombres = ?, apellidos = ?, rol = ?, username = ?, estado = ?, pwd = ?, fecha_actualizado = NOW() WHERE id = ?";
        } else {
            querySQL_1 = "UPDATE usuarios SET nombres = ?, apellidos = ?, rol = ?, username = ?, estado = ?, fecha_actualizado = NOW() WHERE id = ?";
        }

        Object[] parametros = cambiaPassword
                ? new Object[]{usuario.getNombres(), usuario.getApellidos(), usuario.getRol(),
                    usuario.getUsername(), usuario.getEstado(), PasswordUtil.hashear(usuario.getPassword()),
                    usuario.getIdUsuario()}
                : new Object[]{usuario.getNombres(), usuario.getApellidos(), usuario.getRol(),
                    usuario.getUsername(), usuario.getEstado(), usuario.getIdUsuario()};

        db.queryActualizar(querySQL_1, parametros);
        db.cerrarConsulta();
        return true;
    }

    // Eliminación lógica: marca el usuario como inactivo (preserva FKs de empleados/clientes)
    public Boolean eliminarUsuario(Usuario usuario) {
        querySQL_1 = "UPDATE usuarios SET estado = 'inactivo', fecha_eliminado = NOW() WHERE id = ?";
        Object[] parametros = {usuario.getIdUsuario()};
        db.queryActualizar(querySQL_1, parametros);
        db.cerrarConsulta();
        return true;
    }
}
