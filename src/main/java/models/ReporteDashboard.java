package models;

import java.util.List;

// DTO con los datos agregados del panel de reportes de negocio.
// Se serializa directamente a JSON con Gson (campos públicos). Cada lista
// alimenta un gráfico del frontend y la exportación a Excel.
public class ReporteDashboard {

    public String desde;
    public String hasta;
    public Kpis kpis;
    public List<FilaMes> porMes;
    public List<FilaEstado> porEstado;
    public List<FilaTipo> porTipo;
    public List<FilaProducto> topProductos;

    // Indicadores resumen (tarjetas KPI).
    public static class Kpis {
        public long totalReservas;
        public double ingresosHospedaje;
        public double ingresosConsumos;
        public double ticketPromedio;
        public double nochesPromedio;

        public double getIngresosTotales() {
            return ingresosHospedaje + ingresosConsumos;
        }
    }

    // Reservas e ingresos agrupados por mes (YYYY-MM).
    public static class FilaMes {
        public String mes;
        public long cantidad;
        public double ingresos;
    }

    // Reservas agrupadas por estado.
    public static class FilaEstado {
        public String estado;
        public long cantidad;
    }

    // Reservas e ingresos agrupados por tipo de habitación.
    public static class FilaTipo {
        public String tipo;
        public long cantidad;
        public double ingresos;
    }

    // Productos más consumidos (por cantidad e importe).
    public static class FilaProducto {
        public String producto;
        public long cantidad;
        public double importe;
    }
}
