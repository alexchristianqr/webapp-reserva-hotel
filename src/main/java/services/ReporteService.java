package services;

import com.lowagie.text.Document;
import com.lowagie.text.Element;
import com.lowagie.text.Font;
import com.lowagie.text.FontFactory;
import com.lowagie.text.PageSize;
import com.lowagie.text.Paragraph;
import com.lowagie.text.Phrase;
import com.lowagie.text.pdf.PdfPCell;
import com.lowagie.text.pdf.PdfPTable;
import com.lowagie.text.pdf.PdfWriter;
import core.BaseService;
import core.services.MysqlDBService;
import java.awt.Color;
import java.io.ByteArrayOutputStream;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.List;
import models.ReservaConsumo;

// Servicio de reportes: genera en memoria el PDF (datos básicos) de una reserva.
public class ReporteService extends BaseService {

    private static final Font FONT_TITULO = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 18, new Color(33, 37, 41));
    private static final Font FONT_SUBTITULO = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 12, new Color(13, 110, 253));
    private static final Font FONT_LABEL = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 10);
    private static final Font FONT_TEXTO = FontFactory.getFont(FontFactory.HELVETICA, 10);
    private static final Font FONT_TH = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 10, Color.WHITE);
    private static final Color AZUL = new Color(13, 110, 253);

    public ReporteService() {
        db = new MysqlDBService();
    }

    // Genera el PDF de la reserva indicada y lo devuelve como arreglo de bytes.
    public byte[] generarReporteReserva(int idReserva) {
        DatosReserva d = obtenerDatosReserva(idReserva);
        if (d == null) {
            throw new IllegalArgumentException("La reserva #" + idReserva + " no existe");
        }
        List<ReservaConsumo> consumos = new ReservaConsumoService().listarConsumos(idReserva);

        try {
            ByteArrayOutputStream salida = new ByteArrayOutputStream();
            Document doc = new Document(PageSize.A4, 48, 48, 54, 54);
            PdfWriter.getInstance(doc, salida);
            doc.open();

            // Encabezado
            Paragraph titulo = new Paragraph("HOTEL TIERRA COLORADA", FONT_TITULO);
            titulo.setAlignment(Element.ALIGN_CENTER);
            doc.add(titulo);

            Paragraph sub = new Paragraph("Reporte de Reserva N° " + idReserva, FONT_SUBTITULO);
            sub.setAlignment(Element.ALIGN_CENTER);
            sub.setSpacingAfter(16);
            doc.add(sub);

            // Datos de cliente y reserva (dos columnas)
            PdfPTable info = new PdfPTable(2);
            info.setWidthPercentage(100);
            info.setSpacingAfter(16);
            agregarCampo(info, "Cliente:", d.clienteNombre + " " + safe(d.clienteApellido));
            agregarCampo(info, "Documento:", safe(d.clienteDocumento));
            agregarCampo(info, "Habitación:", "Piso " + safe(d.numeroPiso) + " — " + d.habitacion);
            agregarCampo(info, "Estado:", textoEstado(d.estado));
            agregarCampo(info, "Entrada:", soloFecha(d.fechaEntrada));
            agregarCampo(info, "Salida:", soloFecha(d.fechaSalida));
            agregarCampo(info, "Noches:", String.valueOf(d.numeroNoches));
            agregarCampo(info, "Huéspedes:", String.valueOf(d.cantidadHuespedes));
            doc.add(info);

            // Detalle de cargos
            Paragraph detalle = new Paragraph("Detalle de cargos", FONT_SUBTITULO);
            detalle.setSpacingAfter(6);
            doc.add(detalle);

            PdfPTable tabla = new PdfPTable(new float[]{6, 2, 2, 2});
            tabla.setWidthPercentage(100);
            encabezado(tabla, "Concepto");
            encabezado(tabla, "Cant.");
            encabezado(tabla, "P. Unit (S/)");
            encabezado(tabla, "Subtotal (S/)");

            // Línea de la habitación (monto_total = precio * noches)
            celda(tabla, "Hospedaje — " + d.habitacion + " (" + d.numeroNoches + " noche/s)", Element.ALIGN_LEFT);
            celda(tabla, String.valueOf(d.numeroNoches), Element.ALIGN_CENTER);
            celda(tabla, money(d.habitacionPrecio), Element.ALIGN_RIGHT);
            celda(tabla, money(d.montoTotal), Element.ALIGN_RIGHT);

            double totalConsumos = 0;
            for (ReservaConsumo c : consumos) {
                celda(tabla, c.getDescripcionProducto(), Element.ALIGN_LEFT);
                celda(tabla, String.valueOf(c.getCantidad()), Element.ALIGN_CENTER);
                celda(tabla, money(c.getPrecio()), Element.ALIGN_RIGHT);
                celda(tabla, money(c.getSubtotal()), Element.ALIGN_RIGHT);
                totalConsumos += c.getSubtotal();
            }

            double totalGeneral = d.montoTotal + totalConsumos;

            // Fila de total
            PdfPCell etiqueta = new PdfPCell(new Phrase("TOTAL GENERAL", FONT_LABEL));
            etiqueta.setColspan(3);
            etiqueta.setHorizontalAlignment(Element.ALIGN_RIGHT);
            etiqueta.setPadding(6);
            etiqueta.setBackgroundColor(new Color(233, 236, 239));
            tabla.addCell(etiqueta);

            PdfPCell total = new PdfPCell(new Phrase("S/ " + money(totalGeneral), FONT_LABEL));
            total.setHorizontalAlignment(Element.ALIGN_RIGHT);
            total.setPadding(6);
            total.setBackgroundColor(new Color(233, 236, 239));
            tabla.addCell(total);

            doc.add(tabla);

            // Pie
            Paragraph pie = new Paragraph();
            pie.setSpacingBefore(24);
            pie.add(new Phrase("Atendido por: ", FONT_LABEL));
            pie.add(new Phrase(safe(d.empleadoNombre) + " " + safe(d.empleadoApellido), FONT_TEXTO));
            doc.add(pie);

            Paragraph nota = new Paragraph(
                    "Documento generado automáticamente por el sistema de reservas. No tiene validez tributaria.",
                    FontFactory.getFont(FontFactory.HELVETICA_OBLIQUE, 8, Color.GRAY));
            nota.setSpacingBefore(8);
            doc.add(nota);

            doc.close();
            return salida.toByteArray();
        } catch (RuntimeException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new RuntimeException("No se pudo generar el PDF de la reserva", ex);
        }
    }

    private DatosReserva obtenerDatosReserva(int idReserva) {
        querySQL_1 = "SELECT r.monto_total, r.numero_noches, r.cantidad_huespedes, r.estado, r.fecha_entrada, r.fecha_salida, "
                + "COALESCE(pc.nombre, uc.nombres) AS cliente_nombre, COALESCE(pc.apellido, uc.apellidos) AS cliente_apellido, pc.nrodocumento AS cliente_doc, "
                + "h.descripcion AS habitacion, h.precio AS habitacion_precio, h.numero_piso, "
                + "pe.nombre AS empleado_nombre, pe.apellido AS empleado_apellido "
                + "FROM reservas r JOIN clientes c ON c.id = r.id_cliente "
                + "LEFT JOIN personas pc ON pc.id = c.id_persona LEFT JOIN usuarios uc ON uc.id = c.id_usuario "
                + "JOIN habitaciones h ON h.id = r.id_habitacion "
                + "JOIN empleados e ON e.id = r.id_empleado LEFT JOIN personas pe ON pe.id = e.id_persona "
                + "WHERE r.id = ?";
        ResultSet rs = db.queryConsultar(querySQL_1, new Object[]{idReserva});
        try {
            if (!rs.next()) {
                return null;
            }
            DatosReserva d = new DatosReserva();
            d.montoTotal = rs.getDouble("monto_total");
            d.numeroNoches = rs.getInt("numero_noches");
            d.cantidadHuespedes = rs.getInt("cantidad_huespedes");
            d.estado = rs.getString("estado");
            d.fechaEntrada = rs.getString("fecha_entrada");
            d.fechaSalida = rs.getString("fecha_salida");
            d.clienteNombre = rs.getString("cliente_nombre");
            d.clienteApellido = rs.getString("cliente_apellido");
            d.clienteDocumento = rs.getString("cliente_doc");
            d.habitacion = rs.getString("habitacion");
            d.habitacionPrecio = rs.getDouble("habitacion_precio");
            d.numeroPiso = rs.getString("numero_piso");
            d.empleadoNombre = rs.getString("empleado_nombre");
            d.empleadoApellido = rs.getString("empleado_apellido");
            return d;
        } catch (SQLException ex) {
            throw new RuntimeException(ex);
        } finally {
            db.cerrarConsulta();
        }
    }

    private void agregarCampo(PdfPTable tabla, String etiqueta, String valor) {
        PdfPCell c = new PdfPCell();
        c.setBorder(0);
        c.setPadding(3);
        Phrase ph = new Phrase();
        ph.add(new Phrase(etiqueta + " ", FONT_LABEL));
        ph.add(new Phrase(safe(valor), FONT_TEXTO));
        c.addElement(ph);
        tabla.addCell(c);
    }

    private void encabezado(PdfPTable tabla, String texto) {
        PdfPCell c = new PdfPCell(new Phrase(texto, FONT_TH));
        c.setBackgroundColor(AZUL);
        c.setPadding(6);
        c.setHorizontalAlignment(Element.ALIGN_CENTER);
        tabla.addCell(c);
    }

    private void celda(PdfPTable tabla, String texto, int alineacion) {
        PdfPCell c = new PdfPCell(new Phrase(safe(texto), FONT_TEXTO));
        c.setPadding(5);
        c.setHorizontalAlignment(alineacion);
        tabla.addCell(c);
    }

    private String money(double valor) {
        return String.format("%.2f", valor);
    }

    private String soloFecha(String fecha) {
        return (fecha != null && fecha.length() >= 10) ? fecha.substring(0, 10) : safe(fecha);
    }

    private String textoEstado(String estado) {
        if (estado == null) {
            return "-";
        }
        return switch (estado) {
            case "pendiente_pago" -> "Pendiente de pago";
            case "pagado" -> "Pagado";
            case "cancelado" -> "Cancelado";
            case "activo" -> "Activo";
            default -> estado;
        };
    }

    private String safe(String valor) {
        return valor != null ? valor : "-";
    }

    // Estructura interna con los datos de cabecera de la reserva.
    private static class DatosReserva {
        double montoTotal;
        int numeroNoches;
        int cantidadHuespedes;
        String estado;
        String fechaEntrada;
        String fechaSalida;
        String clienteNombre;
        String clienteApellido;
        String clienteDocumento;
        String habitacion;
        double habitacionPrecio;
        String numeroPiso;
        String empleadoNombre;
        String empleadoApellido;
    }
}
