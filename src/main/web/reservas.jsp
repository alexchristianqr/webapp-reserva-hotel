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
                    <button class="btn btn-sm btn-danger me-2" title="Cancelar reserva"
                            :disabled="reserva.estado === 'cancelado'"
                            @click="cancelarReserva(reserva.idReserva)">
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
                modalInstance: null
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

            // Cancelar reserva (eliminación lógica: estado pasa a 'cancelado')
            const cancelarReserva = async (idReserva) => {
                if (!confirm('¿Deseas cancelar esta reserva?'))
                    return;

                try {
                    const formData = new FormData();
                    formData.append('action', 'eliminar');
                    formData.append('id', idReserva);

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

                    await listarReservas();
                } catch (error) {
                    alert(error.message);
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
                cancelarReserva
            };
        }
    }).mount('#app');
</script>

<%@include file="includes/footer.jsp" %>
