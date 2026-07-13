package services;

import core.BaseService;
import core.services.MysqlDBService;
import java.io.ByteArrayOutputStream;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import models.ReporteDashboard;
import models.ReporteDashboard.FilaEstado;
import models.ReporteDashboard.FilaMes;
import models.ReporteDashboard.FilaProducto;
import models.ReporteDashboard.FilaTipo;
import models.ReporteDashboard.Kpis;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.CellStyle;
import org.apache.poi.ss.usermodel.Font;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;

// Servicio de reportes de negocio: agrega datos de reservas, consumos y habitaciones
// para el panel de gráficos (JSON) y para la exportación en Excel (.xlsx con Apache POI).
// El "ingreso" reconocido excluye las reservas en estado 'cancelado'.
public class ReporteNegocioService extends BaseService {

    public ReporteNegocioService() {
        db = new MysqlDBService();
    }

    // ---- Panel (datos para los gráficos y KPIs) -------------------------------------

    public ReporteDashboard obtenerDashboard(String desde, String hasta) {
        String[] rango = normalizarRango(desde, hasta);
        ReporteDashboard dashboard = new ReporteDashboard();
        dashboard.desde = rango[0];
        dashboard.hasta = rango[1];
        dashboard.kpis = obtenerKpis(rango);
        dashboard.porMes = obtenerPorMes(rango);
        dashboard.porEstado = obtenerPorEstado(rango);
        dashboard.porTipo = obtenerPorTipoHabitacion(rango);
        dashboard.topProductos = obtenerTopProductos(rango);
        return dashboard;
    }

    private Kpis obtenerKpis(String[] rango) {
        Kpis kpis = new Kpis();

        querySQL_1 = "SELECT COUNT(*) AS total_reservas, "
                + "IFNULL(SUM(CASE WHEN r.estado <> 'cancelado' THEN r.monto_total ELSE 0 END), 0) AS ingresos_hospedaje, "
                + "IFNULL(AVG(CASE WHEN r.estado <> 'cancelado' THEN r.monto_total END), 0) AS ticket_promedio, "
                + "IFNULL(AVG(r.numero_noches), 0) AS noches_promedio "
                + "FROM reservas r WHERE DATE(r.fecha_reserva) BETWEEN ? AND ?";
        ResultSet rs = db.queryConsultar(querySQL_1, new Object[]{rango[0], rango[1]});
        try {
            if (rs.next()) {
                kpis.totalReservas = rs.getLong("total_reservas");
                kpis.ingresosHospedaje = rs.getDouble("ingresos_hospedaje");
                kpis.ticketPromedio = rs.getDouble("ticket_promedio");
                kpis.nochesPromedio = rs.getDouble("noches_promedio");
            }
        } catch (SQLException ex) {
            throw new RuntimeException(ex);
        } finally {
            db.cerrarConsulta();
        }

        // Los consumos se agregan aparte (relación 1:N con reservas) para no
        // multiplicar el monto_total al mezclar JOINs.
        querySQL_2 = "SELECT IFNULL(SUM(rc.cantidad * rc.precio), 0) AS ingresos_consumos "
                + "FROM reservas_consumo rc JOIN reservas r ON r.id = rc.id_reserva "
                + "WHERE rc.estado = 'activo' AND r.estado <> 'cancelado' "
                + "AND DATE(r.fecha_reserva) BETWEEN ? AND ?";
        ResultSet rsc = db.queryConsultar(querySQL_2, new Object[]{rango[0], rango[1]});
        try {
            if (rsc.next()) {
                kpis.ingresosConsumos = rsc.getDouble("ingresos_consumos");
            }
        } catch (SQLException ex) {
            throw new RuntimeException(ex);
        } finally {
            db.cerrarConsulta();
        }

        return kpis;
    }

    private List<FilaMes> obtenerPorMes(String[] rango) {
        List<FilaMes> filas = new ArrayList<>();
        querySQL_1 = "SELECT DATE_FORMAT(r.fecha_reserva, '%Y-%m') AS mes, COUNT(*) AS cantidad, "
                + "IFNULL(SUM(CASE WHEN r.estado <> 'cancelado' THEN r.monto_total ELSE 0 END), 0) AS ingresos "
                + "FROM reservas r WHERE r.fecha_reserva IS NOT NULL AND DATE(r.fecha_reserva) BETWEEN ? AND ? "
                + "GROUP BY DATE_FORMAT(r.fecha_reserva, '%Y-%m') ORDER BY mes";
        ResultSet rs = db.queryConsultar(querySQL_1, new Object[]{rango[0], rango[1]});
        try {
            while (rs.next()) {
                FilaMes fila = new FilaMes();
                fila.mes = rs.getString("mes");
                fila.cantidad = rs.getLong("cantidad");
                fila.ingresos = rs.getDouble("ingresos");
                filas.add(fila);
            }
            return filas;
        } catch (SQLException ex) {
            throw new RuntimeException(ex);
        } finally {
            db.cerrarConsulta();
        }
    }

    private List<FilaEstado> obtenerPorEstado(String[] rango) {
        List<FilaEstado> filas = new ArrayList<>();
        querySQL_1 = "SELECT r.estado AS estado, COUNT(*) AS cantidad FROM reservas r "
                + "WHERE DATE(r.fecha_reserva) BETWEEN ? AND ? GROUP BY r.estado ORDER BY cantidad DESC";
        ResultSet rs = db.queryConsultar(querySQL_1, new Object[]{rango[0], rango[1]});
        try {
            while (rs.next()) {
                FilaEstado fila = new FilaEstado();
                fila.estado = rs.getString("estado");
                fila.cantidad = rs.getLong("cantidad");
                filas.add(fila);
            }
            return filas;
        } catch (SQLException ex) {
            throw new RuntimeException(ex);
        } finally {
            db.cerrarConsulta();
        }
    }

    private List<FilaTipo> obtenerPorTipoHabitacion(String[] rango) {
        List<FilaTipo> filas = new ArrayList<>();
        querySQL_1 = "SELECT th.descripcion AS tipo, COUNT(*) AS cantidad, "
                + "IFNULL(SUM(CASE WHEN r.estado <> 'cancelado' THEN r.monto_total ELSE 0 END), 0) AS ingresos "
                + "FROM reservas r JOIN habitaciones h ON h.id = r.id_habitacion "
                + "LEFT JOIN tipo_habitacion th ON th.id = h.id_tipohabitacion "
                + "WHERE DATE(r.fecha_reserva) BETWEEN ? AND ? "
                + "GROUP BY th.id, th.descripcion ORDER BY ingresos DESC";
        ResultSet rs = db.queryConsultar(querySQL_1, new Object[]{rango[0], rango[1]});
        try {
            while (rs.next()) {
                FilaTipo fila = new FilaTipo();
                fila.tipo = rs.getString("tipo");
                fila.cantidad = rs.getLong("cantidad");
                fila.ingresos = rs.getDouble("ingresos");
                filas.add(fila);
            }
            return filas;
        } catch (SQLException ex) {
            throw new RuntimeException(ex);
        } finally {
            db.cerrarConsulta();
        }
    }

    private List<FilaProducto> obtenerTopProductos(String[] rango) {
        List<FilaProducto> filas = new ArrayList<>();
        querySQL_1 = "SELECT pr.descripcion AS producto, SUM(rc.cantidad) AS cantidad, "
                + "SUM(rc.cantidad * rc.precio) AS importe "
                + "FROM reservas_consumo rc JOIN productos pr ON pr.id = rc.id_producto "
                + "JOIN reservas r ON r.id = rc.id_reserva "
                + "WHERE rc.estado = 'activo' AND DATE(r.fecha_reserva) BETWEEN ? AND ? "
                + "GROUP BY pr.id, pr.descripcion ORDER BY cantidad DESC LIMIT 10";
        ResultSet rs = db.queryConsultar(querySQL_1, new Object[]{rango[0], rango[1]});
        try {
            while (rs.next()) {
                FilaProducto fila = new FilaProducto();
                fila.producto = rs.getString("producto");
                fila.cantidad = rs.getLong("cantidad");
                fila.importe = rs.getDouble("importe");
                filas.add(fila);
            }
            return filas;
        } catch (SQLException ex) {
            throw new RuntimeException(ex);
        } finally {
            db.cerrarConsulta();
        }
    }

    // ---- Exportación a Excel (.xlsx) ------------------------------------------------

    public byte[] generarExcel(String desde, String hasta) {
        String[] rango = normalizarRango(desde, hasta);
        ReporteDashboard dashboard = obtenerDashboard(rango[0], rango[1]);

        try (Workbook wb = new XSSFWorkbook(); ByteArrayOutputStream salida = new ByteArrayOutputStream()) {
            CellStyle estiloTitulo = estiloTitulo(wb);
            CellStyle estiloCabecera = estiloCabecera(wb);
            CellStyle estiloMoneda = estiloMoneda(wb);

            hojaResumen(wb, dashboard, estiloTitulo, estiloCabecera, estiloMoneda);
            hojaPorMes(wb, dashboard, estiloCabecera, estiloMoneda);
            hojaPorEstado(wb, dashboard, estiloCabecera);
            hojaPorTipo(wb, dashboard, estiloCabecera, estiloMoneda);
            hojaTopProductos(wb, dashboard, estiloCabecera, estiloMoneda);
            hojaDetalleReservas(wb, rango, estiloCabecera, estiloMoneda);

            wb.write(salida);
            return salida.toByteArray();
        } catch (Exception ex) {
            throw new RuntimeException("No se pudo generar el Excel del reporte", ex);
        }
    }

    private void hojaResumen(Workbook wb, ReporteDashboard d, CellStyle titulo, CellStyle cab, CellStyle moneda) {
        Sheet hoja = wb.createSheet("Resumen");
        Row r0 = hoja.createRow(0);
        celda(r0, 0, "Reporte de negocio - Hotel Tierra Colorada", titulo);
        celda(hoja.createRow(1), 0, "Periodo: " + d.desde + " a " + d.hasta, null);

        int i = 3;
        Row cabecera = hoja.createRow(i++);
        celda(cabecera, 0, "Indicador", cab);
        celda(cabecera, 1, "Valor", cab);

        agregarKpi(hoja, i++, "Total de reservas", d.kpis.totalReservas, null);
        agregarKpi(hoja, i++, "Ingresos por hospedaje", d.kpis.ingresosHospedaje, moneda);
        agregarKpi(hoja, i++, "Ingresos por consumos", d.kpis.ingresosConsumos, moneda);
        agregarKpi(hoja, i++, "Ingresos totales", d.kpis.getIngresosTotales(), moneda);
        agregarKpi(hoja, i++, "Ticket promedio", d.kpis.ticketPromedio, moneda);
        agregarKpi(hoja, i++, "Noches promedio", d.kpis.nochesPromedio, null);

        hoja.setColumnWidth(0, 8000);
        hoja.setColumnWidth(1, 5000);
    }

    private void agregarKpi(Sheet hoja, int fila, String etiqueta, double valor, CellStyle moneda) {
        Row row = hoja.createRow(fila);
        celda(row, 0, etiqueta, null);
        Cell c = row.createCell(1);
        c.setCellValue(valor);
        if (moneda != null) {
            c.setCellStyle(moneda);
        }
    }

    private void hojaPorMes(Workbook wb, ReporteDashboard d, CellStyle cab, CellStyle moneda) {
        Sheet hoja = wb.createSheet("Por mes");
        Row cabecera = hoja.createRow(0);
        celda(cabecera, 0, "Mes", cab);
        celda(cabecera, 1, "Reservas", cab);
        celda(cabecera, 2, "Ingresos", cab);
        int i = 1;
        for (FilaMes f : d.porMes) {
            Row row = hoja.createRow(i++);
            celda(row, 0, f.mes, null);
            row.createCell(1).setCellValue(f.cantidad);
            Cell c = row.createCell(2);
            c.setCellValue(f.ingresos);
            c.setCellStyle(moneda);
        }
        autoAncho(hoja, 3);
    }

    private void hojaPorEstado(Workbook wb, ReporteDashboard d, CellStyle cab) {
        Sheet hoja = wb.createSheet("Por estado");
        Row cabecera = hoja.createRow(0);
        celda(cabecera, 0, "Estado", cab);
        celda(cabecera, 1, "Reservas", cab);
        int i = 1;
        for (FilaEstado f : d.porEstado) {
            Row row = hoja.createRow(i++);
            celda(row, 0, f.estado, null);
            row.createCell(1).setCellValue(f.cantidad);
        }
        autoAncho(hoja, 2);
    }

    private void hojaPorTipo(Workbook wb, ReporteDashboard d, CellStyle cab, CellStyle moneda) {
        Sheet hoja = wb.createSheet("Por tipo habitacion");
        Row cabecera = hoja.createRow(0);
        celda(cabecera, 0, "Tipo de habitación", cab);
        celda(cabecera, 1, "Reservas", cab);
        celda(cabecera, 2, "Ingresos", cab);
        int i = 1;
        for (FilaTipo f : d.porTipo) {
            Row row = hoja.createRow(i++);
            celda(row, 0, f.tipo != null ? f.tipo : "(sin tipo)", null);
            row.createCell(1).setCellValue(f.cantidad);
            Cell c = row.createCell(2);
            c.setCellValue(f.ingresos);
            c.setCellStyle(moneda);
        }
        autoAncho(hoja, 3);
    }

    private void hojaTopProductos(Workbook wb, ReporteDashboard d, CellStyle cab, CellStyle moneda) {
        Sheet hoja = wb.createSheet("Top productos");
        Row cabecera = hoja.createRow(0);
        celda(cabecera, 0, "Producto", cab);
        celda(cabecera, 1, "Cantidad", cab);
        celda(cabecera, 2, "Importe", cab);
        int i = 1;
        for (FilaProducto f : d.topProductos) {
            Row row = hoja.createRow(i++);
            celda(row, 0, f.producto, null);
            row.createCell(1).setCellValue(f.cantidad);
            Cell c = row.createCell(2);
            c.setCellValue(f.importe);
            c.setCellStyle(moneda);
        }
        autoAncho(hoja, 3);
    }

    private void hojaDetalleReservas(Workbook wb, String[] rango, CellStyle cab, CellStyle moneda) {
        Sheet hoja = wb.createSheet("Detalle reservas");
        Row cabecera = hoja.createRow(0);
        String[] cols = {"#", "Fecha reserva", "Cliente", "Habitación", "Tipo", "Noches",
            "Huéspedes", "Estado", "Monto", "Check-in", "Check-out"};
        for (int col = 0; col < cols.length; col++) {
            celda(cabecera, col, cols[col], cab);
        }

        querySQL_1 = "SELECT r.id, DATE(r.fecha_reserva) AS fecha_reserva, "
                + "COALESCE(pc.nombre, uc.nombres) AS cliente_nombre, "
                + "COALESCE(pc.apellido, uc.apellidos) AS cliente_apellido, "
                + "h.descripcion AS habitacion, th.descripcion AS tipo, "
                + "r.numero_noches, r.cantidad_huespedes, r.estado, r.monto_total, "
                + "DATE(r.fecha_entrada) AS fecha_entrada, DATE(r.fecha_salida) AS fecha_salida "
                + "FROM reservas r JOIN clientes c ON c.id = r.id_cliente "
                + "LEFT JOIN personas pc ON pc.id = c.id_persona LEFT JOIN usuarios uc ON uc.id = c.id_usuario "
                + "JOIN habitaciones h ON h.id = r.id_habitacion "
                + "LEFT JOIN tipo_habitacion th ON th.id = h.id_tipohabitacion "
                + "WHERE DATE(r.fecha_reserva) BETWEEN ? AND ? ORDER BY r.id DESC";
        ResultSet rs = db.queryConsultar(querySQL_1, new Object[]{rango[0], rango[1]});
        try {
            int i = 1;
            while (rs.next()) {
                Row row = hoja.createRow(i++);
                row.createCell(0).setCellValue(rs.getInt("id"));
                celda(row, 1, rs.getString("fecha_reserva"), null);
                String nombre = (safe(rs.getString("cliente_nombre")) + " " + safe(rs.getString("cliente_apellido"))).trim();
                celda(row, 2, nombre, null);
                celda(row, 3, rs.getString("habitacion"), null);
                celda(row, 4, rs.getString("tipo"), null);
                row.createCell(5).setCellValue(rs.getInt("numero_noches"));
                row.createCell(6).setCellValue(rs.getInt("cantidad_huespedes"));
                celda(row, 7, rs.getString("estado"), null);
                Cell monto = row.createCell(8);
                monto.setCellValue(rs.getDouble("monto_total"));
                monto.setCellStyle(moneda);
                celda(row, 9, rs.getString("fecha_entrada"), null);
                celda(row, 10, rs.getString("fecha_salida"), null);
            }
        } catch (SQLException ex) {
            throw new RuntimeException(ex);
        } finally {
            db.cerrarConsulta();
        }
        autoAncho(hoja, cols.length);
    }

    // ---- Helpers --------------------------------------------------------------------

    private void celda(Row row, int col, String valor, CellStyle estilo) {
        Cell c = row.createCell(col);
        c.setCellValue(valor != null ? valor : "");
        if (estilo != null) {
            c.setCellStyle(estilo);
        }
    }

    private void autoAncho(Sheet hoja, int columnas) {
        for (int i = 0; i < columnas; i++) {
            hoja.autoSizeColumn(i);
        }
    }

    private CellStyle estiloTitulo(Workbook wb) {
        Font font = wb.createFont();
        font.setBold(true);
        font.setFontHeightInPoints((short) 14);
        CellStyle estilo = wb.createCellStyle();
        estilo.setFont(font);
        return estilo;
    }

    private CellStyle estiloCabecera(Workbook wb) {
        Font font = wb.createFont();
        font.setBold(true);
        CellStyle estilo = wb.createCellStyle();
        estilo.setFont(font);
        return estilo;
    }

    private CellStyle estiloMoneda(Workbook wb) {
        CellStyle estilo = wb.createCellStyle();
        estilo.setDataFormat(wb.createDataFormat().getFormat("#,##0.00"));
        return estilo;
    }

    private String safe(String valor) {
        return valor != null ? valor : "";
    }

    // Valida el rango de fechas (YYYY-MM-DD). Si faltan, usa los últimos 6 meses.
    private String[] normalizarRango(String desde, String hasta) {
        LocalDate hoy = LocalDate.now();
        String fin = esFechaValida(hasta) ? hasta : hoy.toString();
        String ini = esFechaValida(desde) ? desde : hoy.minusMonths(6).toString();
        if (ini.compareTo(fin) > 0) {
            String tmp = ini;
            ini = fin;
            fin = tmp;
        }
        return new String[]{ini, fin};
    }

    private boolean esFechaValida(String fecha) {
        if (fecha == null || fecha.length() != 10) {
            return false;
        }
        try {
            LocalDate.parse(fecha);
            return true;
        } catch (Exception e) {
            return false;
        }
    }
}
