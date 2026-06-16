<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@include file="includes/header.jsp" %>

<header class="py-3 border-bottom mb-4">
    <div class="d-flex justify-content-between align-items-center mb-4">
        <h2 class="mb-0">Gestión de Reservas</h2>

        <div class="d-flex gap-2">
            <a href="/webapp-reserva-hotel/home.jsp" class="btn btn-outline-secondary">
                <i class="bi bi-caret-left"></i> Volver
            </a>
            <button class="btn btn-primary mr-5" @click="openModal()">Nueva Reserva</button>
        </div>
    </div>
</header>

<main class="flex-fill">
    <!-- Tabla de reservas -->
    <table class="table table-striped align-middle">
        <thead>
            <tr>
                <th>#</th>
                <th>Cliente</th>
                <th>Habitación</th>
                <th>Entrada</th>
                <th>Salida</th>
                <th>Noches</th>
                <th>Huéspedes</th>
                <th>Monto</th>
                <th>Estado</th>
                <th>Acciones</th>
            </tr>
        </thead>
        <tbody>
            <tr v-for="(reserva, index) in state.reservas" :key="reserva.idReserva">
                <td>{{ index + 1 }}</td>
                <td>{{ reserva.cliente.nombre }}</td>
                <td>{{ reserva.habitacion.descripcion }}</td>
                <td>{{ soloFecha(reserva.fechaEntrada) }}</td>
                <td>{{ soloFecha(reserva.fechaSalida) }}</td>
                <td>{{ reserva.numeroNoches }}</td>
                <td>{{ reserva.cantidadHuespedes }}</td>
                <td>S/ {{ reserva.montoTotal.toFixed(2) }}</td>
                <td>
                    <span class="badge" :class="estadoBadge(reserva.estado)">
                        {{ estadoTexto(reserva.estado) }}
                    </span>
                </td>
                <td>
                    <button class="btn btn-sm btn-primary me-2" title="Editar"
                            :disabled="reserva.estado === 'cancelado'"
                            @click="openModal(reserva)">
                        <i class="bi bi-pencil-square"></i>
                    </button>
                    <button class="btn btn-sm btn-info text-white me-2" title="Consumos y facturación"
                            :disabled="reserva.estado === 'cancelado'"
                            @click="openGestionModal(reserva)">
                        <i class="bi bi-receipt"></i>
                    </button>
                    <a class="btn btn-sm btn-outline-dark me-2" title="Reporte PDF" target="_blank"
                       :href="'/webapp-reserva-hotel/ReporteServlet?action=reserva&id=' + reserva.idReserva">
                        <i class="bi bi-file-earmark-pdf"></i>
                    </a>
                    <button class="btn btn-sm btn-danger me-2" title="Cancelar reserva"
                            :disabled="reserva.estado === 'cancelado'"
                            @click="cancelarReserva(reserva)">
                        <i class="bi bi-x-circle"></i>
                    </button>
                </td>
            </tr>
            <tr v-if="state.reservas.length === 0">
                <td colspan="10" class="text-center text-muted">No hay reservas registradas</td>
            </tr>
        </tbody>
    </table>

    <!-- MODAL Bootstrap para crear/actualizar -->
    <div class="modal fade" id="reservaModal" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered">
            <div class="modal-content">
                <form @submit.prevent="guardarReserva">

                    <div class="modal-header">
                        <h5 class="modal-title">{{ state.modalMode === 'crear' ? 'Nueva Reserva' : 'Editar Reserva' }}</h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                    </div>

                    <div class="modal-body">
                        <div v-if="state.messageError" class="alert alert-danger">
                            {{ state.messageError }}
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Cliente</label>
                            <select v-model="state.form.id_cliente" class="form-select" required>
                                <option selected value="">- Seleccionar -</option>
                                <option v-for="cliente in state.clientes" :value="cliente.idCliente">{{ cliente.nombre }}</option>
                            </select>
                        </div>

                        <div class="row">
                            <div class="col-6 mb-3">
                                <label class="form-label">Fecha Entrada</label>
                                <input type="date" class="form-control" v-model="state.form.fecha_entrada"
                                       :min="state.modalMode === 'crear' ? today : null" required>
                            </div>
                            <div class="col-6 mb-3">
                                <label class="form-label">Fecha Salida</label>
                                <input type="date" class="form-control" v-model="state.form.fecha_salida"
                                       :min="state.form.fecha_entrada" required>
                            </div>
                        </div>

                        <!-- Habitaciones filtradas por disponibilidad según las fechas elegidas -->
                        <div class="mb-3">
                            <label class="form-label">
                                Habitación disponible
                                <span v-if="state.cargandoDisponibilidad" class="spinner-border spinner-border-sm ms-1"></span>
                            </label>
                            <select v-model="state.form.id_habitacion" class="form-select" required>
                                <option selected value="">- Seleccionar -</option>
                                <option v-for="habitacion in state.habitacionesDisponibles" :value="habitacion.idHabitacion">
                                    Piso {{ habitacion.numeroPiso }} — {{ habitacion.descripcion }} (S/ {{ habitacion.precio.toFixed(2) }}/noche)
                                </option>
                            </select>
                            <div v-if="!state.cargandoDisponibilidad && state.habitacionesDisponibles.length === 0" class="form-text text-danger">
                                No hay habitaciones disponibles para las fechas seleccionadas.
                            </div>
                        </div>

                        <div class="row">
                            <div class="col-6 mb-3">
                                <label class="form-label">Huéspedes</label>
                                <input type="number" class="form-control" v-model.number="state.form.cantidad_huespedes"
                                       min="1" :max="camasSeleccionadas * 2 || null" required>
                            </div>
                            <div class="col-6 mb-3" v-if="state.modalMode === 'edit'">
                                <label class="form-label">Estado</label>
                                <select v-model="state.form.estado" class="form-select">
                                    <option value="pendiente_pago">Pendiente de pago</option>
                                    <option value="pagado">Pagado</option>
                                    <option value="activo">Activo</option>
                                </select>
                            </div>
                        </div>

                        <!-- Resumen calculado: el monto definitivo lo recalcula el servidor -->
                        <div v-if="noches > 0 && habitacionSeleccionada" class="alert alert-info py-2 mb-0">
                            <strong>{{ noches }}</strong> noche(s)
                            × S/ {{ habitacionSeleccionada.precio.toFixed(2) }}
                            = <strong>S/ {{ montoEstimado.toFixed(2) }}</strong>
                        </div>
                    </div>

                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancelar</button>
                        <button type="submit" class="btn btn-success" :disabled="state.habitacionesDisponibles.length === 0">
                            {{ state.modalMode === 'crear' ? 'Guardar' : 'Actualizar' }}
                        </button>
                    </div>

                </form>
            </div>
        </div>
    </div>

    <!-- Modal de confirmación de cancelación -->
    <div class="modal fade" id="cancelarModal" tabindex="-1" aria-labelledby="cancelarModalLabel" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered">
            <div class="modal-content">
                <div class="modal-header bg-danger text-white">
                    <h5 class="modal-title" id="cancelarModalLabel">
                        <i class="bi bi-exclamation-triangle me-2"></i>Confirmar cancelación de reserva
                    </h5>
                    <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body" v-if="state.reservaACancelar">
                    <div v-if="state.cancelError" class="alert alert-danger alert-dismissible fade show" role="alert">
                        {{ state.cancelError }}
                        <button type="button" class="btn-close" @click="state.cancelError = null" aria-label="Close"></button>
                    </div>

                    <p>¿Deseas cancelar la siguiente reserva?</p>
                    <ul class="list-group mb-3">
                        <li class="list-group-item d-flex justify-content-between">
                            <strong>Cliente</strong>
                            <span>{{ state.reservaACancelar.cliente.nombre }}</span>
                        </li>
                        <li class="list-group-item d-flex justify-content-between">
                            <strong>Habitación</strong>
                            <span>{{ state.reservaACancelar.habitacion.descripcion }}</span>
                        </li>
                        <li class="list-group-item d-flex justify-content-between">
                            <strong>Estadía</strong>
                            <span>{{ soloFecha(state.reservaACancelar.fechaEntrada) }} → {{ soloFecha(state.reservaACancelar.fechaSalida) }}
                                ({{ state.reservaACancelar.numeroNoches }} noche(s))</span>
                        </li>
                        <li class="list-group-item d-flex justify-content-between">
                            <strong>Monto</strong>
                            <span>S/ {{ state.reservaACancelar.montoTotal.toFixed(2) }}</span>
                        </li>
                    </ul>
                    <p class="text-muted small mb-0">
                        La reserva pasará a estado <span class="badge bg-secondary">cancelado</span> y la
                        habitación volverá a estar disponible para esas fechas. Esta acción no se puede deshacer.
                    </p>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">No, volver</button>
                    <button type="button" class="btn btn-danger" @click="confirmarCancelarReserva">
                        <i class="bi bi-x-circle"></i> Sí, cancelar reserva
                    </button>
                </div>
            </div>
        </div>
    </div>

    <!-- MODAL de gestión: consumos + facturación + reporte -->
    <div class="modal fade" id="gestionModal" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog modal-lg modal-dialog-scrollable">
            <div class="modal-content" v-if="state.gestion.reserva">
                <div class="modal-header">
                    <h5 class="modal-title">
                        <i class="bi bi-receipt me-1"></i>
                        Consumos y facturación — Reserva N° {{ state.gestion.reserva.idReserva }}
                    </h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>

                <div class="modal-body">
                    <div v-if="state.gestion.error" class="alert alert-danger alert-dismissible fade show" role="alert">
                        {{ state.gestion.error }}
                        <button type="button" class="btn-close" @click="state.gestion.error = null"></button>
                    </div>
                    <div v-if="state.gestion.success" class="alert alert-success alert-dismissible fade show" role="alert">
                        {{ state.gestion.success }}
                        <button type="button" class="btn-close" @click="state.gestion.success = null"></button>
                    </div>

                    <!-- Resumen reserva -->
                    <div class="row mb-3">
                        <div class="col-md-6"><strong>Cliente:</strong> {{ state.gestion.reserva.cliente.nombre }}</div>
                        <div class="col-md-6"><strong>Habitación:</strong> {{ state.gestion.reserva.habitacion.descripcion }}</div>
                        <div class="col-md-6">
                            <strong>Estado:</strong>
                            <span class="badge" :class="estadoBadge(state.gestion.reserva.estado)">{{ estadoTexto(state.gestion.reserva.estado) }}</span>
                        </div>
                        <div class="col-md-6"><strong>Hospedaje:</strong> S/ {{ state.gestion.reserva.montoTotal.toFixed(2) }}</div>
                    </div>

                    <!-- Agregar consumo -->
                    <h6 class="text-primary"><i class="bi bi-basket me-1"></i>Productos de consumo</h6>
                    <div class="row g-2 align-items-end mb-3">
                        <div class="col-md-6">
                            <label class="form-label mb-1">Producto</label>
                            <select v-model="state.gestion.nuevoProducto" class="form-select form-select-sm">
                                <option value="">- Seleccionar -</option>
                                <option v-for="p in state.gestion.productos" :value="p.idProducto">
                                    {{ p.descripcion }} (S/ {{ Number(p.precio).toFixed(2) }} · stock {{ p.cantidadStock }})
                                </option>
                            </select>
                        </div>
                        <div class="col-md-3">
                            <label class="form-label mb-1">Cantidad</label>
                            <input type="number" min="1" v-model.number="state.gestion.nuevaCantidad" class="form-control form-control-sm">
                        </div>
                        <div class="col-md-3">
                            <button class="btn btn-sm btn-success w-100" @click="agregarConsumo"
                                    :disabled="!state.gestion.nuevoProducto || state.gestion.reserva.estado === 'cancelado'">
                                <i class="bi bi-plus-lg"></i> Agregar
                            </button>
                        </div>
                    </div>

                    <table class="table table-sm table-bordered align-middle">
                        <thead class="table-light">
                            <tr>
                                <th>Producto</th>
                                <th class="text-center">Cant.</th>
                                <th class="text-end">P. Unit</th>
                                <th class="text-end">Subtotal</th>
                                <th></th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr v-if="state.gestion.consumos.length === 0">
                                <td colspan="5" class="text-center text-muted">Sin consumos registrados</td>
                            </tr>
                            <tr v-for="c in state.gestion.consumos" :key="c.idConsumo">
                                <td>{{ c.descripcionProducto }}</td>
                                <td class="text-center">{{ c.cantidad }}</td>
                                <td class="text-end">S/ {{ c.precio.toFixed(2) }}</td>
                                <td class="text-end">S/ {{ (c.cantidad * c.precio).toFixed(2) }}</td>
                                <td class="text-center">
                                    <button class="btn btn-sm btn-outline-danger" title="Anular"
                                            @click="eliminarConsumo(c)">
                                        <i class="bi bi-trash"></i>
                                    </button>
                                </td>
                            </tr>
                        </tbody>
                        <tfoot>
                            <tr>
                                <th colspan="3" class="text-end">Total consumos</th>
                                <th class="text-end">S/ {{ totalConsumos.toFixed(2) }}</th>
                                <th></th>
                            </tr>
                            <tr class="table-primary">
                                <th colspan="3" class="text-end">TOTAL GENERAL (hospedaje + consumos)</th>
                                <th class="text-end">S/ {{ totalGeneral.toFixed(2) }}</th>
                                <th></th>
                            </tr>
                        </tfoot>
                    </table>

                    <!-- Facturación -->
                    <h6 class="text-primary mt-4"><i class="bi bi-cash-coin me-1"></i>Facturación</h6>
                    <div class="row g-2 align-items-end mb-3">
                        <div class="col-md-6">
                            <label class="form-label mb-1">Tipo de comprobante</label>
                            <select v-model.number="state.gestion.tipoComprobante" class="form-select form-select-sm">
                                <option :value="1">Factura</option>
                                <option :value="2">Boleta</option>
                            </select>
                        </div>
                        <div class="col-md-6">
                            <button class="btn btn-sm btn-primary w-100" @click="generarComprobante"
                                    :disabled="state.gestion.reserva.estado === 'cancelado'">
                                <i class="bi bi-cash-coin"></i> Generar comprobante y marcar pagado
                            </button>
                        </div>
                    </div>

                    <table class="table table-sm table-bordered align-middle">
                        <thead class="table-light">
                            <tr>
                                <th>#</th>
                                <th>Tipo</th>
                                <th class="text-end">Monto</th>
                                <th>Emitido</th>
                                <th>Empleado</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr v-if="state.gestion.comprobantes.length === 0">
                                <td colspan="5" class="text-center text-muted">Sin comprobantes emitidos</td>
                            </tr>
                            <tr v-for="cmp in state.gestion.comprobantes" :key="cmp.idComprobante">
                                <td>{{ cmp.idComprobante }}</td>
                                <td>{{ cmp.tipoComprobante === 1 ? 'Factura' : 'Boleta' }}</td>
                                <td class="text-end">S/ {{ cmp.montoTotal.toFixed(2) }}</td>
                                <td>{{ soloFecha(cmp.fechaPagado || cmp.fechaCreado) }}</td>
                                <td>{{ cmp.nombreEmpleado || '-' }}</td>
                            </tr>
                        </tbody>
                    </table>
                </div>

                <div class="modal-footer">
                    <a class="btn btn-outline-dark me-auto" target="_blank"
                       :href="'/webapp-reserva-hotel/ReporteServlet?action=reserva&id=' + state.gestion.reserva.idReserva">
                        <i class="bi bi-file-earmark-pdf"></i> Ver reporte PDF
                    </a>
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cerrar</button>
                </div>
            </div>
        </div>
    </div>
</main>

<script>
    const {createApp, reactive, computed, watch, onMounted} = Vue;
    const redirectLogin = '/webapp-reserva-hotel/login.jsp';

    const sumarDias = (fecha, dias) => {
        const nueva = new Date(fecha);
        nueva.setDate(nueva.getDate() + dias);
        return nueva.toISOString().substring(0, 10);
    };

    const today = new Date().toISOString().substring(0, 10);
    const tomorrow = sumarDias(today, 1);

    createApp({
        setup() {
            const defaultForm = {
                id_reserva: null,
                id_cliente: "",
                id_habitacion: "",
                id_empleado: 1,
                cantidad_huespedes: 1,
                estado: "",
                fecha_entrada: today,
                fecha_salida: tomorrow
            };
            const state = reactive({
                reservas: [],
                clientes: [],
                habitacionesDisponibles: [],
                cargandoDisponibilidad: false,
                form: {...defaultForm},
                modalMode: 'crear',
                messageError: null,
                modalInstance: null,
                reservaACancelar: null,
                cancelError: null,
                cancelarModalInstance: null,
                gestionModalInstance: null,
                gestion: {
                    reserva: null,
                    consumos: [],
                    comprobantes: [],
                    productos: [],
                    nuevoProducto: "",
                    nuevaCantidad: 1,
                    tipoComprobante: 1,
                    error: null,
                    success: null
                }
            });

            // ---- helpers de presentación ----
            const soloFecha = (fecha) => fecha ? fecha.substring(0, 10) : '';

            const estadoBadge = (estado) => ({
                'activo': 'bg-primary',
                'pendiente_pago': 'bg-warning text-dark',
                'pagado': 'bg-success',
                'cancelado': 'bg-secondary'
            }[estado] || 'bg-light text-dark');

            const estadoTexto = (estado) => ({
                'activo': 'Activo',
                'pendiente_pago': 'Pendiente de pago',
                'pagado': 'Pagado',
                'cancelado': 'Cancelado'
            }[estado] || estado);

            // ---- cálculos del resumen (estimado; el servidor recalcula el monto real) ----
            const noches = computed(() => {
                const entrada = new Date(state.form.fecha_entrada);
                const salida = new Date(state.form.fecha_salida);
                const diff = (salida - entrada) / (1000 * 60 * 60 * 24);
                return diff > 0 ? Math.round(diff) : 0;
            });

            const habitacionSeleccionada = computed(() =>
                state.habitacionesDisponibles.find(h => h.idHabitacion === state.form.id_habitacion) || null
            );

            const camasSeleccionadas = computed(() =>
                habitacionSeleccionada.value ? habitacionSeleccionada.value.cantidadCamas : 0
            );

            const montoEstimado = computed(() =>
                habitacionSeleccionada.value ? habitacionSeleccionada.value.precio * noches.value : 0
            );

            // ---- totales del modal de gestión (consumos + facturación) ----
            const totalConsumos = computed(() =>
                state.gestion.consumos.reduce((acc, c) => acc + (c.cantidad * c.precio), 0)
            );

            const totalGeneral = computed(() =>
                (state.gestion.reserva ? state.gestion.reserva.montoTotal : 0) + totalConsumos.value
            );

            // ---- consulta de disponibilidad al servidor ----
            const consultarDisponibilidad = async () => {
                if (!state.form.fecha_entrada || !state.form.fecha_salida || noches.value <= 0) {
                    state.habitacionesDisponibles = [];
                    return;
                }

                state.cargandoDisponibilidad = true;
                try {
                    const params = new URLSearchParams({
                        action: 'disponibilidad',
                        fecha_entrada: state.form.fecha_entrada,
                        fecha_salida: state.form.fecha_salida
                    });
                    // al editar, la propia reserva no debe bloquear su habitación
                    if (state.modalMode === 'edit' && state.form.id_reserva) {
                        params.append('id_reserva', state.form.id_reserva);
                    }

                    const response = await fetch('ReservaServlet?' + params.toString());

                    if (!response.ok) {
                        if (response.status === 401) {
                            window.location.href = redirectLogin;
                            return;
                        }
                        throw new Error('Error al consultar disponibilidad');
                    }

                    const {success, result, message} = await response.json();
                    if (!success && !result) {
                        throw new Error(message || 'Error al consultar disponibilidad');
                    }

                    state.habitacionesDisponibles = result || [];

                    // si la habitación elegida dejó de estar disponible, se limpia la selección
                    if (!state.habitacionesDisponibles.some(h => h.idHabitacion === state.form.id_habitacion)) {
                        state.form.id_habitacion = "";
                    }
                } catch (error) {
                    console.error(error);
                    state.messageError = error.message;
                } finally {
                    state.cargandoDisponibilidad = false;
                }
            };

            // cada cambio de fechas refresca las habitaciones disponibles
            watch(() => [state.form.fecha_entrada, state.form.fecha_salida], consultarDisponibilidad);

            // Abrir modal en modo crear o editar
            const openModal = (reserva = null) => {
                state.messageError = null;

                if (reserva) {
                    state.modalMode = 'edit';
                    Object.assign(state.form, {
                        id_reserva: reserva.idReserva,
                        id_cliente: reserva.cliente.idCliente,
                        id_habitacion: reserva.habitacion.idHabitacion,
                        id_empleado: reserva.empleado.idEmpleado,
                        cantidad_huespedes: reserva.cantidadHuespedes,
                        estado: reserva.estado,
                        fecha_entrada: soloFecha(reserva.fechaEntrada),
                        fecha_salida: soloFecha(reserva.fechaSalida)
                    });
                } else {
                    state.modalMode = 'crear';
                    Object.assign(state.form, defaultForm);
                }

                consultarDisponibilidad();

                if (!state.modalInstance) {
                    const modalEl = document.getElementById('reservaModal');
                    state.modalInstance = new bootstrap.Modal(modalEl);
                }
                state.modalInstance.show();
            };

            // Guardar o actualizar la reserva (monto y noches los calcula el servidor)
            const guardarReserva = async () => {
                state.messageError = null;

                try {
                    const formData = new FormData();
                    formData.append('action', state.modalMode === 'crear' ? 'crear' : 'actualizar');
                    formData.append('id_cliente', state.form.id_cliente);
                    formData.append('id_habitacion', state.form.id_habitacion);
                    formData.append('id_empleado', state.form.id_empleado);
                    formData.append('cantidad_huespedes', state.form.cantidad_huespedes);
                    formData.append('fecha_entrada', state.form.fecha_entrada);
                    formData.append('fecha_salida', state.form.fecha_salida);

                    if (state.modalMode === 'edit') {
                        formData.append('id_reserva', state.form.id_reserva);
                        formData.append('estado', state.form.estado);
                    }

                    const response = await fetch('ReservaServlet', {
                        method: 'POST',
                        body: formData
                    });

                    if (!response.ok) {
                        if (response.status === 401) {
                            window.location.href = redirectLogin;
                            return;
                        }
                        throw new Error("Error al guardar");
                    }

                    const {success, message} = await response.json();
                    if (!success)
                        throw new Error(message || 'Error al guardar la reserva.');

                    state.modalInstance.hide();
                    await listarReservas();

                } catch (error) {
                    state.messageError = error.message;
                }
            };

            // Abre el modal de confirmación con el detalle de la reserva a cancelar.
            const cancelarReserva = (reserva) => {
                state.reservaACancelar = reserva;
                state.cancelError = null;

                if (!state.cancelarModalInstance) {
                    state.cancelarModalInstance = new bootstrap.Modal(document.getElementById('cancelarModal'));
                }
                state.cancelarModalInstance.show();
            };

            // Cancelar reserva (eliminación lógica: estado pasa a 'cancelado');
            // se ejecuta solo cuando el usuario confirma en el modal.
            const confirmarCancelarReserva = async () => {
                if (!state.reservaACancelar)
                    return;

                try {
                    const formData = new FormData();
                    formData.append('action', 'eliminar');
                    formData.append('id', state.reservaACancelar.idReserva);

                    const response = await fetch('ReservaServlet', {
                        method: 'POST',
                        body: formData
                    });

                    if (!response.ok) {
                        if (response.status === 401) {
                            window.location.href = redirectLogin;
                            return;
                        }
                        throw new Error('Error de red');
                    }

                    const {success, message} = await response.json();

                    if (!success)
                        throw new Error(message || 'Error al cancelar la reserva.');

                    state.cancelarModalInstance.hide();
                    state.reservaACancelar = null;
                    await listarReservas();
                } catch (error) {
                    state.cancelError = error.message;
                }
            };

            // ---- gestión de consumos y facturación ----
            const fetchJson = async (url, options) => {
                const response = await fetch(url, options);
                if (!response.ok) {
                    if (response.status === 401) {
                        window.location.href = redirectLogin;
                        return null;
                    }
                    throw new Error('Error de red (' + response.status + ')');
                }
                return response.json();
            };

            const cargarProductos = async () => {
                try {
                    const data = await fetchJson('ProductoServlet?action=listar');
                    // solo productos activos pueden consumirse
                    state.gestion.productos = (data && data.success ? data.result : [])
                            .filter(p => p.estado === 'activo');
                } catch (e) {
                    console.error(e);
                }
            };

            const cargarConsumos = async (idReserva) => {
                const data = await fetchJson('ConsumoServlet?action=listar&id_reserva=' + idReserva);
                state.gestion.consumos = data && data.success ? data.result : [];
            };

            const cargarComprobantes = async (idReserva) => {
                const data = await fetchJson('ComprobanteServlet?action=listar&id_reserva=' + idReserva);
                state.gestion.comprobantes = data && data.success ? data.result : [];
            };

            const openGestionModal = async (reserva) => {
                state.gestion.reserva = reserva;
                state.gestion.error = null;
                state.gestion.success = null;
                state.gestion.nuevoProducto = "";
                state.gestion.nuevaCantidad = 1;
                state.gestion.tipoComprobante = 1;
                state.gestion.consumos = [];
                state.gestion.comprobantes = [];

                if (!state.gestionModalInstance) {
                    state.gestionModalInstance = new bootstrap.Modal(document.getElementById('gestionModal'));
                }
                state.gestionModalInstance.show();

                await Promise.all([
                    cargarConsumos(reserva.idReserva),
                    cargarComprobantes(reserva.idReserva),
                    state.gestion.productos.length === 0 ? cargarProductos() : Promise.resolve()
                ]);
            };

            const agregarConsumo = async () => {
                state.gestion.error = null;
                state.gestion.success = null;
                try {
                    const formData = new FormData();
                    formData.append('action', 'crear');
                    formData.append('id_reserva', state.gestion.reserva.idReserva);
                    formData.append('id_producto', state.gestion.nuevoProducto);
                    formData.append('cantidad', state.gestion.nuevaCantidad);

                    const data = await fetchJson('ConsumoServlet', {method: 'POST', body: formData});
                    if (!data) return;
                    if (!data.success) throw new Error(data.message);

                    state.gestion.success = data.message;
                    state.gestion.nuevoProducto = "";
                    state.gestion.nuevaCantidad = 1;
                    await Promise.all([cargarConsumos(state.gestion.reserva.idReserva), cargarProductos()]);
                } catch (e) {
                    state.gestion.error = e.message;
                }
            };

            const eliminarConsumo = async (consumo) => {
                state.gestion.error = null;
                state.gestion.success = null;
                try {
                    const formData = new FormData();
                    formData.append('action', 'eliminar');
                    formData.append('id_consumo', consumo.idConsumo);

                    const data = await fetchJson('ConsumoServlet', {method: 'POST', body: formData});
                    if (!data) return;
                    if (!data.success) throw new Error(data.message);

                    state.gestion.success = data.message;
                    await Promise.all([cargarConsumos(state.gestion.reserva.idReserva), cargarProductos()]);
                } catch (e) {
                    state.gestion.error = e.message;
                }
            };

            const generarComprobante = async () => {
                state.gestion.error = null;
                state.gestion.success = null;
                try {
                    const formData = new FormData();
                    formData.append('action', 'crear');
                    formData.append('id_reserva', state.gestion.reserva.idReserva);
                    formData.append('tipo_comprobante', state.gestion.tipoComprobante);

                    const data = await fetchJson('ComprobanteServlet', {method: 'POST', body: formData});
                    if (!data) return;
                    if (!data.success) throw new Error(data.message);

                    state.gestion.success = data.message;
                    // la reserva pasó a 'pagado': reflejarlo en la tabla y en el modal
                    state.gestion.reserva.estado = 'pagado';
                    await cargarComprobantes(state.gestion.reserva.idReserva);
                    await listarReservas();
                } catch (e) {
                    state.gestion.error = e.message;
                }
            };

            // Listar reservas
            const listarReservas = async () => {
                try {
                    const response = await fetch('ReservaServlet?action=listar', {
                        method: 'GET'
                    });

                    if (!response.ok) {
                        if (response.status === 401) {
                            window.location.href = redirectLogin;
                            return;
                        }
                        throw new Error('Error de red');
                    }

                    const {success, result} = await response.json();
                    state.reservas = success ? result : [];
                } catch (error) {
                    console.error(error);
                }
            };

            // Listar clientes
            const listarClientes = async () => {
                try {
                    const response = await fetch('ClienteServlet?action=listar', {
                        method: 'GET'
                    });

                    if (!response.ok) {
                        if (response.status === 401) {
                            window.location.href = redirectLogin;
                            return;
                        }
                        throw new Error('Error de red');
                    }

                    const {success, result} = await response.json();
                    state.clientes = success ? result : [];
                } catch (error) {
                    console.error(error);
                }
            };

            onMounted(async () => {
                await listarReservas();
                await listarClientes();
            });

            return {
                state,
                today,
                noches,
                habitacionSeleccionada,
                camasSeleccionadas,
                montoEstimado,
                soloFecha,
                estadoBadge,
                estadoTexto,
                openModal,
                guardarReserva,
                cancelarReserva,
                confirmarCancelarReserva,
                totalConsumos,
                totalGeneral,
                openGestionModal,
                agregarConsumo,
                eliminarConsumo,
                generarComprobante
            };
        }
    }).mount('#app');
</script>

<%@include file="includes/footer.jsp" %>
