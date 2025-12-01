<%@include file="../includes/header.jsp" %>

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
                <th>Fecha Entrada</th>
                <th>Fecha Salida</th>
                <th>Acciones</th>
            </tr>
        </thead>
        <tbody>
            <tr v-for="(reserva, index) in state.reservas" :key="reserva.idReserva">
                <td>{{ index + 1 }}</td>
                <td>{{ reserva.cliente.nombre }}</td>
                <td>{{ reserva.habitacion.descripcion }}</td>
                <td>{{ reserva.fechaEntrada }}</td>
                <td>{{ reserva.fechaSalida }}</td>
                <td>
                    <button class="btn btn-sm btn-primary me-2" title="Editar" @click="openModal(reserva)">
                        <i class="bi bi-pencil-square"></i>
                    </button>
                    <button class="btn btn-sm btn-danger me-2" title="Eliminar" @click="eliminarReserva(reserva.idReserva)">
                        <i class="bi bi-trash"></i>
                    </button>
                </td>
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
                            <select v-model="state.form.id_cliente" class="form-select" aria-label="Default select example">
                                <option selected value="">- Seleccionar -</option>
                                <option v-for="cliente in state.clientes" :value="cliente.idCliente">{{ cliente.nombre }}</option>
                            </select>           
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Habitacion</label>
                            <select v-model="state.form.id_habitacion" class="form-select" aria-label="Default select example">
                                <option selected value="">- Seleccionar -</option>
                                <option v-for="habitacion in state.habitaciones" :value="habitacion.idHabitacion">{{ habitacion.descripcion }}</option>
                            </select>        
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Fecha Entrada</label>
                            <input type="date" class="form-control" v-model="state.form.fecha_entrada" required>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Fecha Salida</label>
                            <input type="date" class="form-control" v-model="state.form.fecha_salida" required>
                        </div>
                    </div>

                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancelar</button>
                        <button type="submit" class="btn btn-success">
                            {{ state.modalMode === 'crear' ? 'Guardar' : 'Actualizar' }}
                        </button>
                    </div>

                </form>
            </div>
        </div>
    </div>
</main>

<script>
    const {createApp, reactive, onMounted} = Vue;
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
                id_cliente: "",
                id_habitacion: "",
                id_empleado: 1,
                fecha_reserva: today,
                fecha_entrada: today,
                fecha_salida: tomorrow
            };
            const state = reactive({
                reservas: [],
                clientes: [],
                habitaciones: [],
                form: {...defaultForm},
                modalMode: 'crear',
                messageError: null,
                modalInstance: null
            });

            // Abre el modal en modo crear o editar
            const openModal = (reserva = null) => {
                state.messageError = null;

                if (reserva) {
                    state.modalMode = 'edit';
                    Object.assign(state.form, reserva);
                } else {
                    state.modalMode = 'crear';
                    Object.assign(state.form, defaultForm);
                }

                if (!state.modalInstance) {
                    const modalEl = document.getElementById('reservaModal');
                    state.modalInstance = new bootstrap.Modal(modalEl);
                }
                state.modalInstance.show();
            };

            // Guardar o actualizar la reserva
            const guardarReserva = async () => {
                try {
                    const formData = new FormData();
                    for (const key in state.form) {
                        formData.append(key, state.form[key]);
                    }

                    const habitacion = state.habitaciones.find(h => h.idHabitacion === state.form.id_habitacion);
                    const precio = habitacion.precio;
                    formData.append('monto_total', precio);
                    formData.append('estado', "activo");

                    formData.append('action', state.modalMode === 'crear' ? 'crear' : 'actualizar');

                    const response = await fetch('ReservaServlet', {
                        method: 'POST',
                        body: formData
                    });

                    console.error(response);
                    if (!response.ok) {
                        if (response.status === 401) {
                            window.location.href = redirectLogin;
                            return;
                        }
                        throw new Error("Error al guardar");
                    }

                    const {success, message, result} = await response.json();
                    if (!success)
                        throw new Error(message || 'Error al guardar la reserva.');

                    // Actualiza lista local
                    if (state.modalMode === 'crear') {
                        state.reservas.push(result);
                    } else {
                        const index = state.reservas.findIndex(r => r.idReserva === state.form.idReserva);
                        if (index !== -1)
                            state.reservas[index] = result;
                    }

                    state.modalInstance.hide();
                    
                    await listarReservas();
                    
                } catch (error) {
                    state.messageError = error.message;
                }
            };

            // Eliminar reserva
            const eliminarReserva = async (idReserva) => {
                if (!confirm('¿Deseas eliminar esta reserva?'))
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
                        throw new Error(message || 'Error al eliminar reserva.');

                    state.reservas = state.reservas.filter(r => r.idReserva !== idReserva);
                } catch (error) {
                    alert(error.message);
                }
            };

            // Listar reservas
            const listarReservas = async () => {
                state.messageError = null;

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

                    const {success, result, message} = await response.json();
                    console.log({success, result, message});

                    if (success) {
                        state.reservas = result;
                    } else {
                        state.messageError = message || 'Usuario o contraseña incorrectos';
                    }
                } catch (error) {
                    console.error(error);
                    state.messageError = error.message;
                }
            };

            // Listar clientes
            const listarClientes = async () => {
                state.messageError = null;

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

                    const {success, result, message} = await response.json();
                    console.log({success, result, message});

                    if (success) {
                        state.clientes = result;
                    } else {
                        state.messageError = message || 'Error al listar clientes';
                    }
                } catch (error) {
                    console.error(error);
                    state.messageError = error.message;
                }
            };

            // Listar habitaciones
            const listarHabitaciones = async () => {
                state.messageError = null;

                try {
                    const response = await fetch('HabitacionServlet?action=listar', {
                        method: 'GET'
                    });

                    if (!response.ok) {
                        if (response.status === 401) {
                            window.location.href = redirectLogin;
                            return;
                        }
                        throw new Error('Error de red');
                    }

                    const {success, result, message} = await response.json();
                    console.log({success, result, message});

                    if (success) {
                        state.habitaciones = result;
                    } else {
                        state.messageError = message || 'Error al listar habitaciones';
                    }
                } catch (error) {
                    console.error(error);
                    state.messageError = error.message;
                }
            };

            onMounted(async () => {
                await listarReservas();
                await listarClientes();
                await listarHabitaciones();
            });

            return {
                state,
                openModal,
                guardarReserva,
                eliminarReserva
            };
        }
    }).mount('#app');
</script>

<%@include file="../includes/footer.jsp" %>
