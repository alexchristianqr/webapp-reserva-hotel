package services;

import core.services.MysqlDBService;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import models.Cliente;
import models.Empleado;
import models.Habitacion;
import models.Reserva;

public class ReservaService extends BaseService {

    public ReservaService() {
        db = new MysqlDBService();
    }

    public List<Reserva> listarReservas() {

        List<Reserva> reservas = new ArrayList<>();

        querySQL_1 = "SELECT r.id, c.id 'id_cliente', u.nombres AS 'nombre_cliente', e.id 'id_empleado', h.id 'id_habitacion', h.descripcion 'habitacion_descripcion', p.nombre AS 'nombre_empleado', th.descripcion AS 'tipo_habitacion', h.descripcion AS 'habitacion', r.monto_total,r.estado, r.fecha_reserva, r.fecha_entrada, r.fecha_salida, r.fecha_creado, r.fecha_actualizado FROM reservas r JOIN clientes c ON c.id = r.id_cliente LEFT JOIN personas pe ON pe.id = c.id_persona JOIN habitaciones h ON h.id = r.id_habitacion LEFT JOIN tipo_habitacion th ON th.id = h.id_tipohabitacion JOIN empleados e ON e.id = r.id_empleado LEFT JOIN personas p ON p.id = e.id_persona LEFT JOIN usuarios u ON u.id = c.id_usuario;";
        Object[] parametrosSQL_1 = {};
        ResultSet rs = db.queryConsultar(querySQL_1, parametrosSQL_1);

        try {
            while (rs.next()) {
                Reserva reserva = new Reserva();
                reserva.setIdReserva(rs.getInt("id"));

                Cliente cliente = new Cliente();
                cliente.setIdCliente(rs.getInt("id_cliente"));
                cliente.setNombre(rs.getString("nombre_cliente"));
                reserva.setCliente(cliente);

                Empleado empleado = new Empleado();
                empleado.setIdEmpleado(rs.getInt("id_empleado"));
                empleado.setNombre(rs.getString("nombre_empleado"));
                reserva.setEmpleado(empleado);

                Habitacion habitacion = new Habitacion();
                habitacion.setIdHabitacion(rs.getInt("id_habitacion"));
                habitacion.setDescripcion(rs.getString("habitacion_descripcion"));
                reserva.setHabitacion(habitacion);

//                reserva.setTipo(rs.getString("tipo_habitacion"));
                reserva.setMontoTotal(rs.getDouble("monto_total"));
                reserva.setEstado(rs.getString("estado"));
                reserva.setFechaReserva(rs.getString("fecha_reserva"));
                reserva.setFechaEntrada(rs.getString("fecha_entrada"));
                reserva.setFechaSalida(rs.getString("fecha_salida"));
                
                reserva.setFechaCreado(rs.getString("fecha_creado"));
                reserva.setFechaActualizado(rs.getString("fecha_actualizado"));
                reservas.add(reserva);
            }

            return reservas;
        } catch (SQLException ex) {
            throw new RuntimeException(ex);
        } finally {
            db.cerrarConsulta();
        }
    }

    public Boolean crearReserva(Reserva reserva) {
        querySQL_1 = "INSERT INTO reservas ( id_cliente, id_habitacion, id_empleado, monto_total, estado, fecha_reserva, fecha_entrada, fecha_salida, fecha_creado ) VALUES ( ?,?,?,?,?,?,?,?,NOW() );";
        Object[] parametrosSQL_1 = {reserva.getIdCliente(), reserva.getIdHabitacion(), reserva.getIdEmpleado(), reserva.getMontoTotal(), reserva.getEstado(), reserva.getFechaReserva(), reserva.getFechaEntrada(), reserva.getFechaSalida()};
        db.queryInsertar(querySQL_1, parametrosSQL_1);

        db.cerrarConsulta();
        return true;
    }

    public Boolean actualizarReserva(Reserva reserva) {
        querySQL_1 = "UPDATE reservas SET monto_total = ?, estado = ?, fecha_reserva = ?, fecha_entrada = ?, fecha_salida = ?, fecha_actualizado = NOW() WHERE id = ?";
        Object[] parametrosSQL_1 = {reserva.getIdCliente(), reserva.getIdHabitacion(), reserva.getIdEmpleado(), reserva.getMontoTotal(), reserva.getEstado(), reserva.getFechaReserva(), reserva.getFechaEntrada(), reserva.getFechaSalida(), reserva.getIdReserva()};
        db.queryActualizar(querySQL_1, parametrosSQL_1);

        db.cerrarConsulta();
        return true;
    }
}
