package services;

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

    public List<Empleado> listarEmpleados() {
        List<Empleado> empleados = new ArrayList<>();

        querySQL_1 = "SELECT e.id, p.nombre, p.apellido, p.tipo_documento, p.nrodocumento, e.sueldo, e.id_empleado_perfil, p.edad, p.sexo, p.telefono, p.estado, p.fecha_creado, p.fecha_actualizado FROM empleados e JOIN personas p ON p.id = e.id_persona;";
        Object[] parametrosSQL_1 = {};
        ResultSet rs = db.queryConsultar(querySQL_1, parametrosSQL_1);

        try {
            while (rs.next()) {
                Empleado empleado = new Empleado();

                empleado.setIdEmpleado(rs.getInt("id"));
                empleado.setNombre(rs.getString("nombre"));
                empleado.setApellidos(rs.getString("apellido"));
                empleado.setTipoDocumento(rs.getInt("tipo_documento"));
                empleado.setNroDocumento(rs.getString("nrodocumento"));
                empleado.setSueldo(rs.getFloat("sueldo")); // mejor para valores monetarios
                empleado.setIdEmpleado(rs.getInt("id_empleado_perfil"));
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

    public void crearEmpleado(Empleado empleado) {
        querySQL_1 = "INSERT INTO personas (nombre, apellido, tipo_documento, nrodocumento, sexo, estado, edad, telefono, fecha_creado) VALUES (?,?,?,?,?,?,?,?,?)";
        Object[] parametrosSQL_1 = {empleado.getNombre(), empleado.getApellidos(), empleado.getTipoDocumento(), empleado.getNroDocumento(), empleado.getSexo(), empleado.getEstado(), empleado.getEdad(), empleado.getTelefono(), empleado.getFechaCreado()};
        int id_persona = db.queryInsertar(querySQL_1, parametrosSQL_1);

        querySQL_2 = "INSERT INTO empleados (id_persona, id_empleado_perfil, sueldo, fecha_creado) VALUES (?,?,?,NOW())";
        Object[] parametrosSQL_2 = {id_persona, empleado.getIdPerfil(), empleado.getSueldo(), empleado.getFechaCreado()};
        db.queryInsertar(querySQL_2, parametrosSQL_2);

        db.cerrarConsulta();
    }

    public void actualizarEmpleado(Empleado empleado) {
        querySQL_1 = "UPDATE personas SET  nombre = ?, apellido = ?, tipo_documento = ?, nrodocumento = ?, edad = ?, sexo = ?, telefono = ?, estado = ?, fecha_actualizado = NOW() WHERE id = (SELECT id_persona FROM empleados e WHERE e.id = ?)";
        Object[] parametrosSQL_1 = {empleado.getNombre(), empleado.getApellidos(), empleado.getTipoDocumento(), empleado.getNroDocumento(), empleado.getEdad(), empleado.getSexo(), empleado.getTelefono(), empleado.getEstado(), empleado.getIdEmpleado()};
        db.queryActualizar(querySQL_1, parametrosSQL_1);

        querySQL_2 = "UPDATE empleados SET id_empleado_perfil = ?, sueldo = ?, fecha_actualizado = NOW() WHERE id = ?";
        Object[] parametrosSQL_2 = {empleado.getIdPerfil(), empleado.getSueldo(), empleado.getIdEmpleado()};
        db.queryActualizar(querySQL_2, parametrosSQL_2);

        db.cerrarConsulta();
    }
}
