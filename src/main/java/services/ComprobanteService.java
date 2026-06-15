package services;

import core.BaseService;
import core.services.MysqlDBService;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import models.Comprobante;

// Gestiona los comprobantes (facturación) de una reserva. El monto del comprobante es
// la suma del importe de la habitación más los consumos activos de la reserva.
public class ComprobanteService extends BaseService {

    public ComprobanteService() {
        db = new MysqlDBService();
    }

    public List<Comprobante> listarComprobantes(int idReserva) {
        List<Comprobante> comprobantes = new ArrayList<>();

        querySQL_1 = "SELECT cmp.id, cmp.id_reserva, cmp.id_empleado, cmp.tipo_comprobante, cmp.estado, cmp.fecha_creado, cmp.fecha_pagado, "
                + "(r.monto_total + IFNULL((SELECT SUM(rc.cantidad * rc.precio) FROM reservas_consumo rc WHERE rc.id_reserva = cmp.id_reserva AND rc.estado = 'activo'), 0)) AS monto_total, "
                + "pe.nombre AS nombre_empleado "
                + "FROM comprobantes cmp JOIN reservas r ON r.id = cmp.id_reserva "
                + "LEFT JOIN empleados e ON e.id = cmp.id_empleado LEFT JOIN personas pe ON pe.id = e.id_persona "
                + "WHERE cmp.id_reserva = ? ORDER BY cmp.id DESC";
        ResultSet rs = db.queryConsultar(querySQL_1, new Object[]{idReserva});

        try {
            while (rs.next()) {
                comprobantes.add(mapear(rs));
            }
            return comprobantes;
        } catch (SQLException ex) {
            throw new RuntimeException(ex);
        } finally {
            db.cerrarConsulta();
        }
    }

    // Genera un comprobante pagado para la reserva y marca la reserva como 'pagado'.
    public Boolean generarComprobante(int idReserva, int idEmpleado, int tipoComprobante) {
        if (tipoComprobante != 1 && tipoComprobante != 2) {
            throw new IllegalArgumentException("Tipo de comprobante inválido (1=Factura, 2=Boleta)");
        }
        if (idEmpleado <= 0) {
            throw new IllegalArgumentException("No se pudo identificar al empleado que emite el comprobante");
        }

        validarReservaFacturable(idReserva);

        boolean autoCommitOriginal = db.getAutoCommit();
        db.setAutoCommit(false);
        try {
            querySQL_2 = "INSERT INTO comprobantes (id_reserva, id_empleado, tipo_comprobante, estado, fecha_pagado) VALUES (?,?,?, 'pagado', NOW())";
            db.queryInsertar(querySQL_2, new Object[]{idReserva, idEmpleado, tipoComprobante});

            querySQL_3 = "UPDATE reservas SET estado = 'pagado', fecha_actualizado = NOW() WHERE id = ?";
            db.queryActualizar(querySQL_3, new Object[]{idReserva});

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

    private Comprobante mapear(ResultSet rs) throws SQLException {
        Comprobante c = new Comprobante();
        c.setIdComprobante(rs.getInt("id"));
        c.setIdReserva(rs.getInt("id_reserva"));
        c.setIdEmpleado(rs.getInt("id_empleado"));
        c.setNombreEmpleado(rs.getString("nombre_empleado"));
        c.setTipoComprobante(rs.getInt("tipo_comprobante"));
        c.setMontoTotal(rs.getDouble("monto_total"));
        c.setEstado(rs.getString("estado"));
        c.setFechaCreado(rs.getString("fecha_creado"));
        c.setFechaPagado(rs.getString("fecha_pagado"));
        return c;
    }

    private void validarReservaFacturable(int idReserva) {
        querySQL_4 = "SELECT estado FROM reservas WHERE id = ?";
        ResultSet rs = db.queryConsultar(querySQL_4, new Object[]{idReserva});
        try {
            if (!rs.next()) {
                throw new IllegalArgumentException("La reserva no existe");
            }
            if ("cancelado".equalsIgnoreCase(rs.getString("estado"))) {
                throw new IllegalArgumentException("No se puede facturar una reserva cancelada");
            }
        } catch (SQLException ex) {
            throw new RuntimeException(ex);
        } finally {
            db.cerrarConsulta();
        }
    }
}
