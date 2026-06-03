package services;

import core.BaseService;
import core.services.MysqlDBService;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import models.Habitacion;

public class HabitacionService extends BaseService {

    public HabitacionService() {
        db = new MysqlDBService();
    }

    public List<Habitacion> listarHabitaciones(String buscar) {
        List<Habitacion> habitaciones = new ArrayList<>();

        querySQL_1 = "SELECT h.id, h.descripcion, h.id_tipohabitacion, th.descripcion AS tipo_descripcion, h.nivel, h.numero_piso, h.precio, h.cantidad_camas, h.estado, h.fecha_creado, h.fecha_actualizado FROM habitaciones h JOIN tipo_habitacion th ON th.id = h.id_tipohabitacion";
        Object[] parametrosSQL_1 = {};

        // Búsqueda parametrizada (SQL LIKE) por descripción, número o tipo
        if (buscar != null && !buscar.isBlank()) {
            querySQL_1 += " WHERE h.descripcion LIKE ? OR h.numero_piso LIKE ? OR th.descripcion LIKE ?";
            String filtro = "%" + buscar.trim() + "%";

            parametrosSQL_1 = new Object[]{
                    filtro,
                    filtro,
                    filtro
            };
        }

        querySQL_1 += " ORDER BY h.id DESC";

        ResultSet rs = db.queryConsultar(querySQL_1, parametrosSQL_1);

        try {
            while (rs.next()) {
                Habitacion habitacion = new Habitacion();

                habitacion.setIdHabitacion(rs.getInt("id"));
                habitacion.setDescripcion(rs.getString("descripcion"));
                habitacion.setIdTipoHabitacion(rs.getInt("id_tipohabitacion"));
                habitacion.setTipoDescripcion(rs.getString("tipo_descripcion"));
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

    // Lista los tipos de habitación disponibles (para alimentar el <select> del formulario)
    public List<Map<String, Object>> listarTiposHabitacion() {
        List<Map<String, Object>> tipos = new ArrayList<>();

        querySQL_1 = "SELECT id, descripcion FROM tipo_habitacion ORDER BY descripcion";

        ResultSet rs = db.queryConsultar(querySQL_1, new Object[]{});

        try {
            while (rs.next()) {
                Map<String, Object> tipo = new HashMap<>();
                tipo.put("id", rs.getInt("id"));
                tipo.put("descripcion", rs.getString("descripcion"));
                tipos.add(tipo);
            }
            return tipos;
        } catch (SQLException ex) {
            throw new RuntimeException(ex);
        } finally {
            db.cerrarConsulta();
        }
    }

    public Boolean crearHabitacion(Habitacion habitacion) {
        querySQL_1 = "INSERT INTO habitaciones (id_tipohabitacion, descripcion, nivel, numero_piso, precio, cantidad_camas, fecha_creado) VALUES (?,?,?,?,?,?,NOW())";
        Object[] parametros = {
                habitacion.getIdTipoHabitacion(),
                habitacion.getDescripcion(),
                habitacion.getNivel(),
                habitacion.getNumeroPiso(),
                habitacion.getPrecio(),
                habitacion.getCantidadCamas()
        };
        db.queryInsertar(querySQL_1, parametros);

        db.cerrarConsulta();
        return true;
    }

    public Boolean actualizarHabitacion(Habitacion habitacion) {
        querySQL_1 = "UPDATE habitaciones SET id_tipohabitacion = ?, descripcion = ?, nivel = ?, numero_piso = ?, precio = ?, cantidad_camas = ?, estado = ?, fecha_actualizado = NOW() WHERE id = ?";
        Object[] parametros = {
                habitacion.getIdTipoHabitacion(),
                habitacion.getDescripcion(),
                habitacion.getNivel(),
                habitacion.getNumeroPiso(),
                habitacion.getPrecio(),
                habitacion.getCantidadCamas(),
                habitacion.getEstado(),
                habitacion.getIdHabitacion()
        };
        db.queryActualizar(querySQL_1, parametros);

        db.cerrarConsulta();
        return true;
    }

    // Eliminación lógica: marca la habitación como inactiva (preserva FKs de reservas)
    public Boolean eliminarHabitacion(Habitacion habitacion) {
        querySQL_1 = "UPDATE habitaciones SET estado = 'inactivo', fecha_actualizado = NOW() WHERE id = ?";
        Object[] parametros = {habitacion.getIdHabitacion()};
        db.queryActualizar(querySQL_1, parametros);

        db.cerrarConsulta();
        return true;
    }
}
