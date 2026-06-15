package services;

import core.BaseService;
import core.services.MysqlDBService;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import models.Empleado;

public class EmpleadoService extends BaseService {

    public EmpleadoService() {
        db = new MysqlDBService();
    }

    public List<Empleado> listarEmpleados(String buscar) {
        List<Empleado> empleados = new ArrayList<>();

        querySQL_1 = "SELECT e.id, e.id_usuario, u.username, p.nombre, p.apellido, p.tipo_documento, p.nrodocumento, e.sueldo, e.id_empleado_perfil, p.edad, p.sexo, p.telefono, e.estado, e.fecha_creado, e.fecha_actualizado "
                + "FROM empleados e JOIN personas p ON p.id = e.id_persona LEFT JOIN usuarios u ON u.id = e.id_usuario";
        Object[] parametrosSQL_1 = {};

        // Búsqueda parametrizada (SQL LIKE) por nombre, apellido o documento
        if (buscar != null && !buscar.isBlank()) {
            querySQL_1 += " WHERE p.nombre LIKE ? OR p.apellido LIKE ? OR p.nrodocumento LIKE ?";
            String like = "%" + buscar.trim() + "%";
            parametrosSQL_1 = new Object[]{like, like, like};
        }

        querySQL_1 += " ORDER BY e.id DESC";
        ResultSet rs = db.queryConsultar(querySQL_1, parametrosSQL_1);

        try {
            while (rs.next()) {
                Empleado empleado = new Empleado();

                empleado.setIdEmpleado(rs.getInt("id"));
                empleado.setIdUsuario(rs.getInt("id_usuario"));
                empleado.setUsername(rs.getString("username"));
                empleado.setNombre(rs.getString("nombre"));
                empleado.setApellidos(rs.getString("apellido"));
                empleado.setTipoDocumento(rs.getInt("tipo_documento"));
                empleado.setNroDocumento(rs.getString("nrodocumento"));
                empleado.setSueldo(rs.getFloat("sueldo")); // mejor para valores monetarios
                empleado.setIdPerfil(rs.getInt("id_empleado_perfil"));
                empleado.setEdad(rs.getString("edad"));
                empleado.setSexo(rs.getString("sexo"));
                empleado.setTelefono(rs.getString("telefono"));
                empleado.setEstado(rs.getString("estado"));
                empleado.setFechaCreado(rs.getString("fecha_creado"));
                empleado.setFechaActualizado(rs.getString("fecha_actualizado"));

                empleados.add(empleado);
            }

            return empleados;
        } catch (SQLException ex) {
            throw new RuntimeException(ex);
        } finally {
            db.cerrarConsulta();
        }

    }

    // Crea, en una sola transacción, la cadena usuario -> persona -> empleado.
    public Boolean crearEmpleado(Empleado empleado) {
        validarDatosCuenta(empleado);

        boolean autoCommitOriginal = db.getAutoCommit();
        db.setAutoCommit(false);
        try {
            // 1) Cuenta de acceso (usuarios)
            querySQL_1 = "INSERT INTO usuarios (nombres, apellidos, rol, username, pwd, estado) VALUES (?,?,'empleado',?,?,?)";
            Object[] parametrosSQL_1 = {
                empleado.getNombre(), empleado.getApellidos(),
                empleado.getUsername(), empleado.getPassword(),
                estadoOActivo(empleado.getEstado())
            };
            int idUsuario = db.queryInsertar(querySQL_1, parametrosSQL_1);

            // 2) Datos personales (personas)
            querySQL_2 = "INSERT INTO personas (nombre, apellido, tipo_documento, nrodocumento, sexo, edad, telefono, estado) VALUES (?,?,?,?,?,?,?,?)";
            Object[] parametrosSQL_2 = {
                empleado.getNombre(), empleado.getApellidos(), empleado.getTipoDocumento(),
                empleado.getNroDocumento(), empleado.getSexo(), empleado.getEdad(),
                empleado.getTelefono(), estadoOActivo(empleado.getEstado())
            };
            int idPersona = db.queryInsertar(querySQL_2, parametrosSQL_2);

            // 3) Empleado enlazando persona + usuario + perfil
            querySQL_3 = "INSERT INTO empleados (id_persona, id_usuario, id_empleado_perfil, sueldo, estado) VALUES (?,?,?,?,?)";
            Object[] parametrosSQL_3 = {
                idPersona, idUsuario, empleado.getIdPerfil(),
                empleado.getSueldo(), estadoOActivo(empleado.getEstado())
            };
            db.queryInsertar(querySQL_3, parametrosSQL_3);

            db.commit();
            return true;
        } catch (RuntimeException ex) {
            db.rollback();
            throw traducirError(ex);
        } finally {
            db.setAutoCommit(autoCommitOriginal);
            db.cerrarConsulta();
        }
    }

    public Boolean actualizarEmpleado(Empleado empleado) {
        boolean autoCommitOriginal = db.getAutoCommit();
        db.setAutoCommit(false);
        try {
            querySQL_1 = "UPDATE personas SET nombre = ?, apellido = ?, tipo_documento = ?, nrodocumento = ?, edad = ?, sexo = ?, telefono = ?, estado = ?, fecha_actualizado = NOW() WHERE id = (SELECT id_persona FROM empleados e WHERE e.id = ?)";
            Object[] parametrosSQL_1 = {empleado.getNombre(), empleado.getApellidos(), empleado.getTipoDocumento(), empleado.getNroDocumento(), empleado.getEdad(), empleado.getSexo(), empleado.getTelefono(), empleado.getEstado(), empleado.getIdEmpleado()};
            db.queryActualizar(querySQL_1, parametrosSQL_1);

            querySQL_2 = "UPDATE empleados SET id_empleado_perfil = ?, sueldo = ?, estado = ?, fecha_actualizado = NOW() WHERE id = ?";
            Object[] parametrosSQL_2 = {empleado.getIdPerfil(), empleado.getSueldo(), empleado.getEstado(), empleado.getIdEmpleado()};
            db.queryActualizar(querySQL_2, parametrosSQL_2);

            querySQL_3 = "UPDATE usuarios SET estado = ?, fecha_actualizado = NOW() WHERE id = (SELECT id_usuario FROM empleados e WHERE e.id = ?)";
            Object[] parametrosSQL_3 = {empleado.getEstado(), empleado.getIdEmpleado()};
            db.queryActualizar(querySQL_3, parametrosSQL_3);

            db.commit();
            return true;
        } catch (RuntimeException ex) {
            db.rollback();
            throw traducirError(ex);
        } finally {
            db.setAutoCommit(autoCommitOriginal);
            db.cerrarConsulta();
        }
    }

    // Eliminación lógica: marca empleado, persona y usuario como inactivos (preserva FKs de reservas/comprobantes)
    public Boolean eliminarEmpleado(Empleado empleado) {
        boolean autoCommitOriginal = db.getAutoCommit();
        db.setAutoCommit(false);
        try {
            querySQL_1 = "UPDATE personas SET estado = 'inactivo', fecha_actualizado = NOW() WHERE id = (SELECT id_persona FROM empleados e WHERE e.id = ?)";
            db.queryActualizar(querySQL_1, new Object[]{empleado.getIdEmpleado()});

            querySQL_2 = "UPDATE empleados SET estado = 'inactivo', fecha_actualizado = NOW() WHERE id = ?";
            db.queryActualizar(querySQL_2, new Object[]{empleado.getIdEmpleado()});

            querySQL_3 = "UPDATE usuarios SET estado = 'inactivo', fecha_actualizado = NOW() WHERE id = (SELECT id_usuario FROM empleados e WHERE e.id = ?)";
            db.queryActualizar(querySQL_3, new Object[]{empleado.getIdEmpleado()});

            db.commit();
            return true;
        } catch (RuntimeException ex) {
            db.rollback();
            throw ex;
        } finally {
            db.setAutoCommit(autoCommitOriginal);
            db.cerrarConsulta();
        }
    }

    private void validarDatosCuenta(Empleado empleado) {
        if (empleado.getUsername() == null || empleado.getUsername().isBlank()
                || empleado.getPassword() == null || empleado.getPassword().isBlank()) {
            throw new IllegalArgumentException("Debe indicar correo y contraseña para la cuenta del empleado");
        }
    }

    private String estadoOActivo(String estado) {
        return (estado != null && !estado.isBlank()) ? estado : "activo";
    }

    private RuntimeException traducirError(RuntimeException ex) {
        String msg = ex.getMessage() != null ? ex.getMessage().toLowerCase() : "";
        if (msg.contains("duplicate") && msg.contains("username")) {
            return new IllegalArgumentException("El correo ya está registrado para otra cuenta activa");
        }
        if (msg.contains("duplicate") && msg.contains("nrodocumento")) {
            return new IllegalArgumentException("Ya existe una persona con ese tipo y número de documento");
        }
        return ex;
    }
}
