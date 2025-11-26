package services;

import core.services.MysqlDBService;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import models.Habitacion;

public class HabitacionService extends BaseService {

    public HabitacionService() {
        db = new MysqlDBService();
    }

    public List<Habitacion> listarHabitaciones() {
        List<Habitacion> habitaciones = new ArrayList<>();

        querySQL_1 = "SELECT id,descripcion,id_tipohabitacion,nivel,numero_piso,precio,cantidad_camas,estado,fecha_creado,fecha_actualizado FROM habitaciones";
        Object[] parametrosSQL_1 = {};
        ResultSet rs = db.queryConsultar(querySQL_1, parametrosSQL_1);

        try {
            while (rs.next()) {
                Habitacion habitacion = new Habitacion();

                habitacion.setIdHabitacion(rs.getInt("id"));
                habitacion.setDescripcion(rs.getString("descripcion"));
                habitacion.setIdTipoHabitacion(rs.getInt("id_tipohabitacion"));
                habitacion.setNivel(rs.getString("nivel"));
                habitacion.setNumeroPiso(rs.getString("numero_piso"));
                habitacion.setPrecio(rs.getFloat("precio")); // BigDecimal para valores monetarios
                habitacion.setCantidadCamas(rs.getInt("cantidad_camas"));
                habitacion.setEstado(rs.getString("estado"));
                habitacion.setFechaCreado(rs.getString("fecha_creado"));
                habitacion.setFechaActualizado(rs.getString("fecha_actualizado"));

                habitaciones.add(habitacion);
            }

            return habitaciones;
        } catch (SQLException ex) {
            throw new RuntimeException(ex);
        } finally {
            db.cerrarConsulta();
        }
    }

    public Boolean crearHabitacion(Habitacion habitacion) {
        querySQL_1 = "INSERT INTO habitaciones (id_tipohabitacion, descripcion, nivel, numero_piso, precio, cantidad_camas, fecha_creado) VALUES (?,?,?,?,?,?,?)";
        //Object[] parametrosSQL_2 = {habitacion.getIdHabitacion(), habitacion.getDescripcion(), habitacion.getNivel(), habitacion.getNumeroPiso(), habitacion.getPrecio(), habitacion.getCantidadCamas(), habitacion.getFechaCreado()};
        Object[] parametrosSQL_2 = {1, habitacion.getDescripcion(), habitacion.getNivel(), habitacion.getNumeroPiso(), habitacion.getPrecio(), habitacion.getCantidadCamas(), habitacion.getFechaCreado()};
        db.queryInsertar(querySQL_1, parametrosSQL_2);

        db.cerrarConsulta();
        return true;
    }

    public Boolean actualizarHabitacion(Habitacion habitacion) {
        querySQL_1 = "UPDATE habitaciones SET estado = ? WHERE id = ?";
        Object[] parametrosSQL_1 = {habitacion.getEstado(), habitacion.getIdHabitacion()};
        db.queryActualizar(querySQL_1, parametrosSQL_1);

        db.cerrarConsulta();
        return true;
    }
}
