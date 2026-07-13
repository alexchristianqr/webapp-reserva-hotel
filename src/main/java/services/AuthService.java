package services;

import core.BaseService;
import core.services.MysqlDBService;
import core.utils.PasswordUtil;
import java.sql.ResultSet;
import java.sql.SQLException;
import models.Empleado;
import models.Usuario;

public class AuthService extends BaseService {

    public AuthService() {
        db = new MysqlDBService();
    }

    public Usuario login(String username, String pwd) {
        try {
            ResultSet rs_1, rs_2, rs_3, rs_4;

            // 1) Buscamos la cuenta por usuario (NO por contraseña: bcrypt incluye
            //    la sal en el hash, así que la verificación se hace en Java).
            querySQL_1 = "SELECT u.rol, u.pwd FROM usuarios u WHERE u.username = ? AND u.estado = 'activo' LIMIT 1;";
            Object[] parametrosSQL_1 = {username};
            rs_1 = db.queryConsultar(querySQL_1, parametrosSQL_1);

            String rol = "";
            String hashGuardado = null;

            if (rs_1.next()) {
                rol = rs_1.getString("rol");
                hashGuardado = rs_1.getString("pwd");
            }

            // 2) Verificamos la contraseña contra el hash guardado.
            if (!PasswordUtil.verificar(pwd, hashGuardado)) {
                return null;
            }

            // Migración transparente: si la contraseña estaba en texto plano
            // (cuenta heredada), la re-guardamos como hash bcrypt al iniciar sesión.
            if (!PasswordUtil.esHashBcrypt(hashGuardado)) {
                rehashearPassword(username, pwd);
            }

            switch (rol) {
                case "empleado":
                    querySQL_2 = "SELECT u.*, e.id AS 'id_empleado', e.id_persona FROM usuarios u JOIN empleados e ON e.id_usuario = u.id AND e.estado = 'activo' WHERE u.username = ? AND u.estado = 'activo' LIMIT 1;";
                    break;
//                case "cliente":
//                    querySQL_2 = "SELECT u.*, c.id AS 'id_cliente', c.id_persona FROM usuarios u JOIN clientes c ON c.id_usuario = u.id AND c.estado = 'activo' WHERE u.username = ? AND u.estado = 'activo' LIMIT 1;";
//                    break;
                default:
                    return null;
            }

            Object[] parametrosSQL_2 = {username};
            rs_2 = db.queryConsultar(querySQL_2, parametrosSQL_2);

            Usuario usuario = new Usuario();
            Empleado empleado;
//            Cliente cliente;

            while (rs_2.next()) {

                usuario.setIdUsuario(rs_2.getInt("id"));
                usuario.setIdPersona(rs_2.getInt("id_persona"));
                usuario.setNombres(rs_2.getString("nombres"));
                usuario.setApellidos(rs_2.getString("apellidos"));
                usuario.setRol(rs_2.getString("rol"));
                usuario.setUsername(rs_2.getString("username"));
                usuario.setPassword(rs_2.getString("pwd"));
                usuario.setEstado(rs_2.getString("estado"));
                usuario.setFechaCreado(rs_2.getString("fecha_creado"));

                switch (rol) {
                    case "empleado": {
                        usuario.setIdEmpleado(rs_2.getInt("id_empleado"));
                        empleado = new Empleado();

                        /* OBTENER DATOS DEL EMPLEADO */
                        querySQL_3 = "SELECT * FROM empleados e WHERE e.id = ? LIMIT 1;";
                        Object[] parametrosSQL_3 = {usuario.getIdEmpleado()};
                        rs_3 = db.queryConsultar(querySQL_3, parametrosSQL_3);

                        while (rs_3.next()) {
                            empleado.setIdEmpleado(rs_3.getInt("id"));
                            empleado.setIdPersona(rs_3.getInt("id_persona"));
                            empleado.setIdUsuario(rs_3.getInt("id_usuario"));
                            empleado.setEstado(rs_3.getString("estado"));
                            empleado.setFechaCreado(rs_3.getString("fecha_creado"));
                            empleado.setFechaActualizado(rs_3.getString("fecha_actualizado"));
                        }

                        /* OBTENER DATOS DE LA PERSONA */
                        querySQL_4 = "SELECT * FROM personas p WHERE p.id = ? LIMIT 1;";
                        Object[] parametrosSQL_4 = {usuario.getIdPersona()};
                        rs_4 = db.queryConsultar(querySQL_4, parametrosSQL_4);

                        while (rs_4.next()) {
                            empleado.setIdPersona(rs_4.getInt("id"));
                            empleado.setNombre(rs_4.getString("nombre"));
                            empleado.setApellidos(rs_4.getString("apellido"));
                            empleado.setTipoDocumento(rs_4.getInt("tipo_documento"));
                            empleado.setNroDocumento(rs_4.getString("nrodocumento"));
                            empleado.setSexo(rs_4.getString("sexo"));
                            empleado.setEdad(rs_4.getString("edad"));
                            empleado.setTelefono(rs_4.getString("telefono"));
                            empleado.setEstado(rs_4.getString("estado"));
                            empleado.setFechaCreado(rs_4.getString("fecha_creado"));
                            empleado.setFechaActualizado(rs_4.getString("fecha_actualizado"));
                        }

                        usuario.setEmpleado(empleado);
                    }
                    break;
//                    case "cliente":
//                        usuario.setIdCliente(rs_2.getInt("id_clientess"));
//                        cliente = new Cliente();
//
//                        /* OBTENER DATOS DEL CLIENTE */
//                        querySQL_3 = "SELECT * FROM clientes c WHERE c.id = ? LIMIT 1;";
//                        Object[] parametrosSQL_3 = {usuario.getIdCliente()};
//                        rs_3 = db.queryConsultar(querySQL_3, parametrosSQL_3);
//
//                        while (rs_3.next()) {
//                            cliente.setIdCliente(rs_3.getInt("id"));
//                            cliente.setIdPersona(rs_3.getInt("id_persona"));
//                            cliente.setIdUsuario(rs_3.getInt("id_usuario"));
//                            cliente.setEstado(rs_3.getString("estado"));
//                            cliente.setFechaCreado(rs_3.getString("fecha_creado"));
//                            cliente.setFechaActualizado(rs_3.getString("fecha_actualizado"));
//                        }
//
//                        /* OBTENER DATOS DE LA PERSONA */
//                        querySQL_4 = "SELECT * FROM personas p WHERE p.id = ? LIMIT 1;";
//                        Object[] parametrosSQL_4 = {usuario.getIdPersona()};
//                        rs_4 = db.queryConsultar(querySQL_4, parametrosSQL_4);
//
//                        while (rs_4.next()) {
//                            cliente.setIdPersona(rs_4.getInt("id"));
//                            cliente.setNombre(rs_4.getString("nombre"));
//                            cliente.setApellidos(rs_4.getString("apellido"));
//                            cliente.setTipoDocumento(rs_4.getInt("tipo_documento"));
//                            cliente.setNroDocumento(rs_4.getString("nrodocumento"));
//                            cliente.setSexo(rs_4.getString("sexo"));
//                            cliente.setEdad(rs_4.getString("edad"));
//                            cliente.setTelefono(rs_4.getString("telefono"));
//                            cliente.setEstado(rs_4.getString("estado"));
//                            cliente.setFechaCreado(rs_4.getString("fecha_creado"));
//                            cliente.setFechaActualizado(rs_4.getString("fecha_actualizado"));
//                        }
//
//                        usuario.setCliente(cliente);
//
//                        success = true;
//
//                        break;
                    default:
                        throw new RuntimeException("Rol no permitido");
                }
            }

            // Si la cuenta no tiene un empleado activo vinculado, la segunda consulta
            // (JOIN empleados) no devuelve filas y 'usuario' queda vacío. En ese caso
            // el login es inválido: evitamos guardar una sesión en blanco.
            if (usuario.getIdUsuario() == 0) {
                return null;
            }

            // No exponemos el hash de la contraseña hacia el cliente/sesión.
            usuario.setPassword(null);

            return usuario;

        } catch (SQLException ex) {
            throw new RuntimeException(ex);
        } finally {
            db.cerrarConsulta();
        }
    }

    // Re-guarda una contraseña heredada (texto plano) como hash bcrypt.
    private void rehashearPassword(String username, String passwordPlano) {
        String sql = "UPDATE usuarios SET pwd = ? WHERE username = ?";
        db.queryActualizar(sql, new Object[]{PasswordUtil.hashear(passwordPlano), username});
    }

    public boolean logout() {
        boolean success = true;

        /*try {
            var usuario = UsuarioThreadLocal.get();

            // Eliminar usuario en sesión local
            if (usuario != null) {
                UsuarioThreadLocal.remove();
                success = true;
            }
        } catch (Exception e) {
            throw new RuntimeException(e);
        }*/
        return success;
    }
}
