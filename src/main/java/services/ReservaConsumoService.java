package services;

import core.BaseService;
import core.services.MysqlDBService;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import models.ReservaConsumo;

// Gestiona los consumos de productos de una reserva y mantiene el stock de productos.
public class ReservaConsumoService extends BaseService {

    public ReservaConsumoService() {
        db = new MysqlDBService();
    }

    public List<ReservaConsumo> listarConsumos(int idReserva) {
        List<ReservaConsumo> consumos = new ArrayList<>();

        querySQL_1 = "SELECT rc.id, rc.id_reserva, rc.id_producto, pr.descripcion, rc.cantidad, rc.precio, rc.estado, rc.fecha_creado "
                + "FROM reservas_consumo rc JOIN productos pr ON pr.id = rc.id_producto "
                + "WHERE rc.id_reserva = ? AND rc.estado = 'activo' ORDER BY rc.id DESC";
        ResultSet rs = db.queryConsultar(querySQL_1, new Object[]{idReserva});

        try {
            while (rs.next()) {
                ReservaConsumo consumo = new ReservaConsumo();
                consumo.setIdConsumo(rs.getInt("id"));
                consumo.setIdReserva(rs.getInt("id_reserva"));
                consumo.setIdProducto(rs.getInt("id_producto"));
                consumo.setDescripcionProducto(rs.getString("descripcion"));
                consumo.setCantidad(rs.getInt("cantidad"));
                consumo.setPrecio(rs.getDouble("precio"));
                consumo.setEstado(rs.getString("estado"));
                consumo.setFechaCreado(rs.getString("fecha_creado"));
                consumos.add(consumo);
            }
            return consumos;
        } catch (SQLException ex) {
            throw new RuntimeException(ex);
        } finally {
            db.cerrarConsulta();
        }
    }

    // Suma de los consumos activos de la reserva (cantidad * precio unitario)
    public double totalConsumos(int idReserva) {
        querySQL_2 = "SELECT IFNULL(SUM(cantidad * precio), 0) AS total FROM reservas_consumo WHERE id_reserva = ? AND estado = 'activo'";
        ResultSet rs = db.queryConsultar(querySQL_2, new Object[]{idReserva});
        try {
            return rs.next() ? rs.getDouble("total") : 0;
        } catch (SQLException ex) {
            throw new RuntimeException(ex);
        } finally {
            db.cerrarConsulta();
        }
    }

    // Agrega un consumo a la reserva: toma el precio vigente del producto, valida stock
    // y descuenta el inventario, todo en una sola transacción.
    public Boolean agregarConsumo(int idReserva, int idProducto, int cantidad) {
        if (cantidad < 1) {
            throw new IllegalArgumentException("La cantidad debe ser al menos 1");
        }

        validarReservaFacturable(idReserva);

        // precio y stock vigentes del producto (no se confían al navegador)
        double precio;
        int stock;
        querySQL_3 = "SELECT precio, cantidad_stock, estado FROM productos WHERE id = ?";
        ResultSet rs = db.queryConsultar(querySQL_3, new Object[]{idProducto});
        try {
            if (!rs.next()) {
                throw new IllegalArgumentException("El producto seleccionado no existe");
            }
            if (!"activo".equalsIgnoreCase(rs.getString("estado"))) {
                throw new IllegalArgumentException("El producto seleccionado está inactivo");
            }
            precio = rs.getDouble("precio");
            stock = rs.getInt("cantidad_stock");
        } catch (SQLException ex) {
            throw new RuntimeException(ex);
        } finally {
            db.cerrarConsulta();
        }

        if (stock < cantidad) {
            throw new IllegalArgumentException("Stock insuficiente. Disponible: " + stock);
        }

        boolean autoCommitOriginal = db.getAutoCommit();
        db.setAutoCommit(false);
        try {
            querySQL_1 = "INSERT INTO reservas_consumo (id_reserva, id_producto, cantidad, precio) VALUES (?,?,?,?)";
            db.queryInsertar(querySQL_1, new Object[]{idReserva, idProducto, cantidad, precio});

            querySQL_2 = "UPDATE productos SET cantidad_stock = cantidad_stock - ?, fecha_actualizado = NOW() WHERE id = ?";
            db.queryActualizar(querySQL_2, new Object[]{cantidad, idProducto});

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

    // Anula un consumo (eliminación lógica) y devuelve la cantidad al stock del producto.
    public Boolean eliminarConsumo(int idConsumo) {
        int idProducto;
        int cantidad;
        querySQL_3 = "SELECT id_producto, cantidad, estado FROM reservas_consumo WHERE id = ?";
        ResultSet rs = db.queryConsultar(querySQL_3, new Object[]{idConsumo});
        try {
            if (!rs.next()) {
                throw new IllegalArgumentException("El consumo no existe");
            }
            if (!"activo".equalsIgnoreCase(rs.getString("estado"))) {
                return true; // ya estaba anulado
            }
            idProducto = rs.getInt("id_producto");
            cantidad = rs.getInt("cantidad");
        } catch (SQLException ex) {
            throw new RuntimeException(ex);
        } finally {
            db.cerrarConsulta();
        }

        boolean autoCommitOriginal = db.getAutoCommit();
        db.setAutoCommit(false);
        try {
            querySQL_1 = "UPDATE reservas_consumo SET estado = 'inactivo', fecha_actualizado = NOW() WHERE id = ?";
            db.queryActualizar(querySQL_1, new Object[]{idConsumo});

            querySQL_2 = "UPDATE productos SET cantidad_stock = cantidad_stock + ?, fecha_actualizado = NOW() WHERE id = ?";
            db.queryActualizar(querySQL_2, new Object[]{cantidad, idProducto});

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

    private void validarReservaFacturable(int idReserva) {
        querySQL_4 = "SELECT estado FROM reservas WHERE id = ?";
        ResultSet rs = db.queryConsultar(querySQL_4, new Object[]{idReserva});
        try {
            if (!rs.next()) {
                throw new IllegalArgumentException("La reserva no existe");
            }
            String estado = rs.getString("estado");
            if ("cancelado".equalsIgnoreCase(estado)) {
                throw new IllegalArgumentException("No se pueden registrar consumos en una reserva cancelada");
            }
        } catch (SQLException ex) {
            throw new RuntimeException(ex);
        } finally {
            db.cerrarConsulta();
        }
    }
}
