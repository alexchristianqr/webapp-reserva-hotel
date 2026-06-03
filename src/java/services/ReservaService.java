package services;

import core.services.MysqlDBService;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;

import models.Cliente;
import models.Empleado;
import models.Habitacion;
import models.Reserva;

public class ReservaService extends BaseService {

    private static final DateTimeFormatter FORMATO_FECHA = DateTimeFormatter.ofPattern("yyyy-MM-dd");

    public ReservaService() {
        db = new MysqlDBService();
    }

    public List<Reserva> listarReservas() {

        List<Reserva> reservas = new ArrayList<>();

        querySQL_1 = "SELECT r.id, c.id 'id_cliente', u.nombres AS 'nombre_cliente', e.id 'id_empleado', h.id 'id_habitacion', h.descripcion 'habitacion_descripcion', p.nombre AS 'nombre_empleado', th.descripcion AS 'tipo_habitacion', h.descripcion AS 'habitacion', r.monto_total, r.numero_noches, r.cantidad_huespedes, r.estado, r.fecha_reserva, r.fecha_entrada, r.fecha_salida, r.fecha_creado, r.fecha_actualizado FROM reservas r JOIN clientes c ON c.id = r.id_cliente LEFT JOIN personas pe ON pe.id = c.id_persona JOIN habitaciones h ON h.id = r.id_habitacion LEFT JOIN tipo_habitacion th ON th.id = h.id_tipohabitacion JOIN empleados e ON e.id = r.id_empleado LEFT JOIN personas p ON p.id = e.id_persona LEFT JOIN usuarios u ON u.id = c.id_usuario ORDER BY r.id DESC;";
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

                reserva.setMontoTotal(rs.getDouble("monto_total"));
                reserva.setNumeroNoches(rs.getInt("numero_noches"));
                reserva.setCantidadHuespedes(rs.getInt("cantidad_huespedes"));
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

    // Valida el rango de fechas y devuelve el número de noches (salida - entrada)
    private long validarFechas(String fechaEntrada, String fechaSalida, boolean exigirEntradaFutura) {
        if (fechaEntrada == null || fechaSalida == null) {
            throw new IllegalArgumentException("Debe indicar fecha de entrada y fecha de salida");
        }

        LocalDate entrada = LocalDate.parse(fechaEntrada, FORMATO_FECHA);
        LocalDate salida = LocalDate.parse(fechaSalida, FORMATO_FECHA);

        if (!salida.isAfter(entrada)) {
            throw new IllegalArgumentException("La fecha de salida debe ser mayor que la fecha de entrada");
        }
        if (exigirEntradaFutura && entrada.isBefore(LocalDate.now())) {
            throw new IllegalArgumentException("La fecha de entrada no puede ser anterior a hoy");
        }

        return ChronoUnit.DAYS.between(entrada, salida);
    }

    // Regla de solape de fechas: una reserva no cancelada choca con el rango pedido si
    // (entrada existente < salida nueva) Y (salida existente > entrada nueva).
    // idReservaExcluir permite ignorar la propia reserva al editar (0 = ninguna).
    public boolean verificarDisponibilidad(int idHabitacion, String fechaEntrada, String fechaSalida, int idReservaExcluir) {
        querySQL_2 = "SELECT COUNT(*) AS total FROM reservas WHERE id_habitacion = ? AND estado <> 'cancelado' AND fecha_entrada < ? AND fecha_salida > ? AND id <> ?";
        Object[] parametrosSQL_2 = {idHabitacion, fechaSalida, fechaEntrada, idReservaExcluir};
        ResultSet rs = db.queryConsultar(querySQL_2, parametrosSQL_2);

        try {
            return rs.next() && rs.getInt("total") == 0;
        } catch (SQLException ex) {
            throw new RuntimeException(ex);
        } finally {
            db.cerrarConsulta();
        }
    }

    // Habitaciones activas SIN reservas que se solapen con el rango de fechas pedido
    public List<Habitacion> listarHabitacionesDisponibles(String fechaEntrada, String fechaSalida, int idReservaExcluir) {
        validarFechas(fechaEntrada, fechaSalida, false);

        List<Habitacion> habitaciones = new ArrayList<>();

        querySQL_3 = "SELECT h.id, h.descripcion, th.descripcion AS tipo_descripcion, h.nivel, h.numero_piso, h.precio, h.cantidad_camas FROM habitaciones h LEFT JOIN tipo_habitacion th ON th.id = h.id_tipohabitacion WHERE h.estado = 'activo' AND h.id NOT IN (SELECT r.id_habitacion FROM reservas r WHERE r.estado <> 'cancelado' AND r.fecha_entrada < ? AND r.fecha_salida > ? AND r.id <> ?) ORDER BY h.numero_piso, h.id";
        Object[] parametrosSQL_3 = {fechaSalida, fechaEntrada, idReservaExcluir};
        ResultSet rs = db.queryConsultar(querySQL_3, parametrosSQL_3);

        try {
            while (rs.next()) {
                Habitacion habitacion = new Habitacion();
                habitacion.setIdHabitacion(rs.getInt("id"));
                habitacion.setDescripcion(rs.getString("descripcion"));
                habitacion.setTipoDescripcion(rs.getString("tipo_descripcion"));
                habitacion.setNivel(rs.getString("nivel"));
                habitacion.setNumeroPiso(rs.getString("numero_piso"));
                habitacion.setPrecio(rs.getDouble("precio"));
                habitacion.setCantidadCamas(rs.getInt("cantidad_camas"));
                habitaciones.add(habitacion);
            }
            return habitaciones;
        } catch (SQLException ex) {
            throw new RuntimeException(ex);
        } finally {
            db.cerrarConsulta();
        }
    }

    // Precio por noche leído de la BD (el monto NO se confía al navegador)
    private double obtenerPrecioHabitacion(int idHabitacion) {
        querySQL_4 = "SELECT precio FROM habitaciones WHERE id = ? AND estado = 'activo'";
        Object[] parametrosSQL_4 = {idHabitacion};
        ResultSet rs = db.queryConsultar(querySQL_4, parametrosSQL_4);

        try {
            if (rs.next()) {
                return rs.getDouble("precio");
            }
            throw new IllegalArgumentException("La habitación seleccionada no existe o está inactiva");
        } catch (SQLException ex) {
            throw new RuntimeException(ex);
        } finally {
            db.cerrarConsulta();
        }
    }

    public Boolean crearReserva(Reserva reserva) {
        long noches = validarFechas(reserva.getFechaEntrada(), reserva.getFechaSalida(), true);

        if (reserva.getCantidadHuespedes() < 1) {
            throw new IllegalArgumentException("Debe indicar al menos un huésped");
        }
        if (!verificarDisponibilidad(reserva.getIdHabitacion(), reserva.getFechaEntrada(), reserva.getFechaSalida(), 0)) {
            throw new IllegalArgumentException("La habitación no está disponible en las fechas seleccionadas");
        }

        double montoTotal = obtenerPrecioHabitacion(reserva.getIdHabitacion()) * noches;
        String estado = (reserva.getEstado() != null && !reserva.getEstado().isBlank())
                ? reserva.getEstado() : "pendiente_pago";

        querySQL_1 = "INSERT INTO reservas ( id_cliente, id_habitacion, id_empleado, monto_total, numero_noches, cantidad_huespedes, estado, fecha_reserva, fecha_entrada, fecha_salida, fecha_creado ) VALUES ( ?,?,?,?,?,?,?,NOW(),?,?,NOW() );";
        Object[] parametrosSQL_1 = {reserva.getIdCliente(), reserva.getIdHabitacion(), reserva.getIdEmpleado(), montoTotal, noches, reserva.getCantidadHuespedes(), estado, reserva.getFechaEntrada(), reserva.getFechaSalida()};
        db.queryInsertar(querySQL_1, parametrosSQL_1);

        db.cerrarConsulta();
        return true;
    }

    public Boolean actualizarReserva(Reserva reserva) {
        long noches = validarFechas(reserva.getFechaEntrada(), reserva.getFechaSalida(), false);

        if (reserva.getCantidadHuespedes() < 1) {
            throw new IllegalArgumentException("Debe indicar al menos un huésped");
        }
        // al editar se excluye la propia reserva del chequeo de solape
        if (!verificarDisponibilidad(reserva.getIdHabitacion(), reserva.getFechaEntrada(), reserva.getFechaSalida(), reserva.getIdReserva())) {
            throw new IllegalArgumentException("La habitación no está disponible en las fechas seleccionadas");
        }

        double montoTotal = obtenerPrecioHabitacion(reserva.getIdHabitacion()) * noches;

        querySQL_1 = "UPDATE reservas SET id_cliente = ?, id_habitacion = ?, monto_total = ?, numero_noches = ?, cantidad_huespedes = ?, estado = ?, fecha_entrada = ?, fecha_salida = ?, fecha_actualizado = NOW() WHERE id = ?";
        Object[] parametrosSQL_1 = {reserva.getIdCliente(), reserva.getIdHabitacion(), montoTotal, noches, reserva.getCantidadHuespedes(), reserva.getEstado(), reserva.getFechaEntrada(), reserva.getFechaSalida(), reserva.getIdReserva()};
        db.queryActualizar(querySQL_1, parametrosSQL_1);

        db.cerrarConsulta();
        return true;
    }

    // Cancelación lógica: la reserva queda en el historial y libera la habitación
    public Boolean cancelarReserva(int idReserva) {
        querySQL_1 = "UPDATE reservas SET estado = 'cancelado', fecha_actualizado = NOW() WHERE id = ?";
        Object[] parametrosSQL_1 = {idReserva};
        int filas = db.queryActualizar(querySQL_1, parametrosSQL_1);

        db.cerrarConsulta();
        return filas > 0;
    }
}
