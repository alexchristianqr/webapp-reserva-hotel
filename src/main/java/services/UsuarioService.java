package services;

import core.BaseService;
import core.services.MysqlDBService;
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

    public boolean registrarUsuario(Usuario usuario) {
        boolean success = false;

        try {
            // Validaciones de entrada
            if (usuario == null || usuario.getNombres() == null || usuario.getApellidos() == null || usuario.getRol() == null || usuario.getUsername() == null || usuario.getPassword() == null) {
                throw new IllegalArgumentException("Datos del usuario incompletos o nulos.");
            }

            String rol = usuario.getRol();

            // Insertar usuario
            querySQL_1 = "INSERT INTO usuarios (nombres, apellidos, rol, username, pwd) VALUES (?,?,?,?,?)";
            Object[] parametrosSQL_1 = {usuario.getNombres(), usuario.getApellidos(), rol, usuario.getUsername(), usuario.getPassword()};
            int id_usuario = db.queryInsertar(querySQL_1, parametrosSQL_1);

            if (id_usuario > 0) {
                switch (rol) {
                    case "cliente" :{
                        // Insertar candidato
                        ClienteService clienteService = new ClienteService();
                        Cliente cliente = new Cliente();
//                        cliente.setIdUsuario(id_usuario);
                        cliente.setNombre(usuario.getNombres());
                        cliente.setApellidos(usuario.getApellidos());
                        cliente.setEstado("activo");
                        clienteService.crearCliente(cliente);

                        success = true;
                        break;
                    }
                    case "empleado" : {
                        // Insertar reclutador
                        EmpleadoService empleadoService = new EmpleadoService();
                        Empleado empleado = new Empleado();
                        empleado.setIdUsuario(id_usuario);
                        empleado.setNombre(usuario.getNombres());
                        empleado.setApellidos(usuario.getApellidos());
                        empleadoService.crearEmpleado(empleado);

                        success = true;
                        break;
                    }
                    default :
                        throw new AssertionError();
                }
            } else {
                throw new RuntimeException("No se pudo insertar el usuario en la base de datos.");
            }
        } catch (RuntimeException e) {
            throw new RuntimeException("Error al registrar el usuario: " + e.getMessage(), e);
        } finally {
            db.cerrarConsulta();
        }

        return success;
    }

    // Actualiza los datos de la cuenta de usuario (no modifica la contraseña)
    public Boolean actualizarUsuario(Usuario usuario) {
        querySQL_1 = "UPDATE usuarios SET nombres = ?, apellidos = ?, rol = ?, username = ?, estado = ?, fecha_actualizado = NOW() WHERE id = ?";
        Object[] parametros = {
            usuario.getNombres(),
            usuario.getApellidos(),
            usuario.getRol(),
            usuario.getUsername(),
            usuario.getEstado(),
            usuario.getIdUsuario()
        };
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
