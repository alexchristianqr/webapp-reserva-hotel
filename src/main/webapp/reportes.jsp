<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@include file="includes/header.jsp" %>

<!-- Chart.js solo se carga en esta página (no en header.jsp, para no cargarlo en todo el sitio) -->
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.3/dist/chart.umd.min.js"></script>

<header class="py-3 border-bottom mb-4">
    <div class="d-flex justify-content-between align-items-center mb-4">
        <h2 class="mb-0"><i class="bi bi-bar-chart-line me-2"></i>Reportes de negocio</h2>
        <div class="d-flex gap-2">
            <a href="${pageContext.request.contextPath}/home.jsp" class="btn btn-outline-secondary">
                <i class="bi bi-caret-left"></i> Volver
            </a>
            <a class="btn btn-success"
               :href="'${pageContext.request.contextPath}/ReporteServlet?action=excel&desde=' + state.desde + '&hasta=' + state.hasta">
                <i class="bi bi-file-earmark-excel"></i> Descargar Excel
            </a>
        </div>
    </div>

    <!-- Filtro de periodo -->
    <div class="row g-2 align-items-end">
        <div class="col-md-3">
            <label class="form-label mb-1">Desde</label>
            <input v-model="state.desde" type="date" class="form-control">
        </div>
        <div class="col-md-3">
            <label class="form-label mb-1">Hasta</label>
            <input v-model="state.hasta" type="date" class="form-control">
        </div>
        <div class="col-md-3">
            <button class="btn btn-primary" @click="cargarReporte">
                <i class="bi bi-funnel"></i> Aplicar
            </button>
        </div>
    </div>
</header>

<main class="flex-fill">
    <div v-if="state.messageError" class="alert alert-danger alert-dismissible fade show" role="alert">
        {{ state.messageError }}
        <button type="button" class="btn-close" @click="state.messageError = null" aria-label="Close"></button>
    </div>

    <!-- Tarjetas KPI -->
    <div class="row g-3 mb-4">
        <div class="col-md-3 col-6">
            <div class="card text-center h-100">
                <div class="card-body">
                    <div class="text-muted small">Reservas</div>
                    <div class="fs-3 fw-bold text-primary">{{ state.kpis.totalReservas }}</div>
                </div>
            </div>
        </div>
        <div class="col-md-3 col-6">
            <div class="card text-center h-100">
                <div class="card-body">
                    <div class="text-muted small">Ingresos totales</div>
                    <div class="fs-4 fw-bold text-success">S/ {{ money(state.kpis.ingresosTotales) }}</div>
                </div>
            </div>
        </div>
        <div class="col-md-3 col-6">
            <div class="card text-center h-100">
                <div class="card-body">
                    <div class="text-muted small">Ticket promedio</div>
                    <div class="fs-4 fw-bold">S/ {{ money(state.kpis.ticketPromedio) }}</div>
                </div>
            </div>
        </div>
        <div class="col-md-3 col-6">
            <div class="card text-center h-100">
                <div class="card-body">
                    <div class="text-muted small">Noches promedio</div>
                    <div class="fs-4 fw-bold">{{ money(state.kpis.nochesPromedio) }}</div>
                </div>
            </div>
        </div>
    </div>

    <div class="text-muted small mb-2">
        Ingresos por hospedaje: S/ {{ money(state.kpis.ingresosHospedaje) }} &middot;
        Ingresos por consumos: S/ {{ money(state.kpis.ingresosConsumos) }}
    </div>

    <!-- Gráficos -->
    <div class="row g-4">
        <div class="col-lg-8">
            <div class="card h-100">
                <div class="card-header">Reservas e ingresos por mes</div>
                <div class="card-body"><canvas id="chartMes"></canvas></div>
            </div>
        </div>
        <div class="col-lg-4">
            <div class="card h-100">
                <div class="card-header">Reservas por estado</div>
                <div class="card-body"><canvas id="chartEstado"></canvas></div>
            </div>
        </div>
        <div class="col-lg-6">
            <div class="card h-100">
                <div class="card-header">Ingresos por tipo de habitación</div>
                <div class="card-body"><canvas id="chartTipo"></canvas></div>
            </div>
        </div>
        <div class="col-lg-6">
            <div class="card h-100">
                <div class="card-header">Top productos consumidos</div>
                <div class="card-body"><canvas id="chartProductos"></canvas></div>
            </div>
        </div>
    </div>
</main>

<script>
    const {createApp, reactive, onMounted} = Vue;
    const redirectLogin = '${pageContext.request.contextPath}/login.jsp';

    createApp({
        setup() {
            const state = reactive({
                desde: '',
                hasta: '',
                kpis: {totalReservas: 0, ingresosHospedaje: 0, ingresosConsumos: 0,
                       ingresosTotales: 0, ticketPromedio: 0, nochesPromedio: 0},
                messageError: null,
            });

            // Instancias de Chart.js (se destruyen y recrean al reaplicar el filtro).
            const charts = {mes: null, estado: null, tipo: null, productos: null};

            const money = (v) => Number(v || 0).toLocaleString('es-PE', {minimumFractionDigits: 2, maximumFractionDigits: 2});

            const estadoLabel = (e) => ({
                activo: 'Activo', pendiente_pago: 'Pendiente de pago',
                pagado: 'Pagado', cancelado: 'Cancelado'
            }[e] || e);

            const cargarReporte = async () => {
                state.messageError = null;
                try {
                    const url = '${pageContext.request.contextPath}/ReporteServlet?action=dashboard'
                            + '&desde=' + (state.desde || '') + '&hasta=' + (state.hasta || '');
                    const response = await fetch(url);

                    if (!response.ok) {
                        if (response.status === 401) {
                            window.location.href = redirectLogin;
                            return;
                        }
                        throw new Error('Error de red, estado: ' + response.status);
                    }

                    const data = await response.json();
                    if (!data.success) {
                        throw new Error(data.message || 'No se pudo cargar el reporte');
                    }

                    const d = data.result;
                    // Sincroniza el filtro con el rango que realmente aplicó el backend.
                    state.desde = d.desde;
                    state.hasta = d.hasta;
                    state.kpis = {
                        totalReservas: d.kpis.totalReservas,
                        ingresosHospedaje: d.kpis.ingresosHospedaje,
                        ingresosConsumos: d.kpis.ingresosConsumos,
                        ingresosTotales: d.kpis.ingresosHospedaje + d.kpis.ingresosConsumos,
                        ticketPromedio: d.kpis.ticketPromedio,
                        nochesPromedio: d.kpis.nochesPromedio,
                    };
                    renderCharts(d);
                } catch (error) {
                    console.error('ERROR en cargarReporte:', error);
                    state.messageError = 'Error al cargar el reporte: ' + error.message;
                }
            };

            const PALETA = ['#0d6efd', '#198754', '#ffc107', '#dc3545', '#6f42c1', '#20c997', '#fd7e14'];

            const renderCharts = (d) => {
                Object.values(charts).forEach(c => { if (c) c.destroy(); });

                // Reservas e ingresos por mes (barras + línea)
                charts.mes = new Chart(document.getElementById('chartMes'), {
                    data: {
                        labels: d.porMes.map(f => f.mes),
                        datasets: [
                            {type: 'bar', label: 'Reservas', data: d.porMes.map(f => f.cantidad),
                             backgroundColor: '#0d6efd', yAxisID: 'y'},
                            {type: 'line', label: 'Ingresos (S/)', data: d.porMes.map(f => f.ingresos),
                             borderColor: '#198754', backgroundColor: '#198754', yAxisID: 'y1', tension: 0.3}
                        ]
                    },
                    options: {
                        responsive: true,
                        scales: {
                            y: {type: 'linear', position: 'left', beginAtZero: true, title: {display: true, text: 'Reservas'}},
                            y1: {type: 'linear', position: 'right', beginAtZero: true, grid: {drawOnChartArea: false}, title: {display: true, text: 'Ingresos'}}
                        }
                    }
                });

                // Reservas por estado (dona)
                charts.estado = new Chart(document.getElementById('chartEstado'), {
                    type: 'doughnut',
                    data: {
                        labels: d.porEstado.map(f => estadoLabel(f.estado)),
                        datasets: [{data: d.porEstado.map(f => f.cantidad), backgroundColor: PALETA}]
                    },
                    options: {responsive: true, plugins: {legend: {position: 'bottom'}}}
                });

                // Ingresos por tipo de habitación (barras)
                charts.tipo = new Chart(document.getElementById('chartTipo'), {
                    type: 'bar',
                    data: {
                        labels: d.porTipo.map(f => f.tipo || '(sin tipo)'),
                        datasets: [{label: 'Ingresos (S/)', data: d.porTipo.map(f => f.ingresos), backgroundColor: '#6f42c1'}]
                    },
                    options: {responsive: true, plugins: {legend: {display: false}}, scales: {y: {beginAtZero: true}}}
                });

                // Top productos consumidos (barras horizontales por cantidad)
                charts.productos = new Chart(document.getElementById('chartProductos'), {
                    type: 'bar',
                    data: {
                        labels: d.topProductos.map(f => f.producto),
                        datasets: [{label: 'Cantidad', data: d.topProductos.map(f => f.cantidad), backgroundColor: '#fd7e14'}]
                    },
                    options: {indexAxis: 'y', responsive: true, plugins: {legend: {display: false}}, scales: {x: {beginAtZero: true}}}
                });
            };

            onMounted(cargarReporte);

            return {state, money, cargarReporte};
        }
    }).mount('#app');
</script>

<%@include file="includes/footer.jsp" %>
