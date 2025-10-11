<%@include file="../includes/header.jsp" %>

<header class="py-3 border-bottom mb-4">
    <div class="d-flex align-items-center justify-content-between">
        <a href="/webapp-reserva-hotel/home.jsp" class="btn btn-link btn-lg text-decoration-none">
            <i class="bi bi-caret-left"></i> Regresar
        </a>
        <h2 class="mb-0 text-center flex-grow-1">Gestión de Reservas</h2>
    </div>
</header>

<main>
    <div class="d-flex justify-content-between align-items-center mb-4">
        <h3>Mis Reservas</h3>
        <button class="btn btn-primary" @click="openModal()">Nueva Reserva</button>
    </div>

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
                <td>{{ reserva.habitacion.decripcion }}</td>
                <td>{{ reserva.fechaEntrada }}</td>
                <td>{{ reserva.fechaSalida }}</td>
                <td>
                    <button class="btn btn-sm btn-warning me-2" @click="openModal(reserva)">Editar</button>
                    <button class="btn btn-sm btn-danger" @click="deleteReserva(reserva.idReserva)">Eliminar</button>
                </td>
            </tr>
        </tbody>
    </table>

    <!-- MODAL Bootstrap para crear/actualizar -->
    <div class="modal fade" id="reservaModal" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered">
            <div class="modal-content">
                <div class="modal-header bg-light">
                    <h5 class="modal-title">{{ state.modalMode === 'create' ? 'Nueva Reserva' : 'Editar Reserva' }}</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>

                <div class="modal-body">
                    <div v-if="state.messageError" class="alert alert-danger">
                        {{ state.messageError }}
                    </div>
                    <form @submit.prevent="saveReserva">
                        <div class="mb-3">
                            <label class="form-label">Cliente</label>
                            <input type="text" class="form-control" v-model="state.form.cliente.nombre" required>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Habitación</label>
                            <input type="text" class="form-control" v-model="state.form.habitacion.descripcion" required>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Fecha Entrada</label>
                            <input type="date" class="form-control" v-model="state.form.fechaEntrada" required>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Fecha Salida</label>
                            <input type="date" class="form-control" v-model="state.form.fechaSalida" required>
                        </div>
                        <div class="text-end">
                            <button type="submit" class="btn btn-success">
                                {{ state.modalMode === 'create' ? 'Guardar' : 'Actualizar' }}
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>
</main>

<script>
    const {createApp, reactive, onMounted} = Vue;

    createApp({
        setup() {
            const state = reactive({
                reservas: [],
                form: {
                    idReserva: null,
                    cliente: '',
                    habitacion: '',
                    fechaEntrada: '',
                    fechaSalida: ''
                },
                modalMode: 'create',
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
                    state.modalMode = 'create';
                    Object.keys(state.form).forEach(k => state.form[k] = '');
                }

                if (!state.modalInstance) {
                    const modalEl = document.getElementById('reservaModal');
                    state.modalInstance = new bootstrap.Modal(modalEl);
                }
                state.modalInstance.show();
            };

            // Guardar o actualizar la reserva
            const saveReserva = async () => {
                try {
                    const formData = new FormData();
                    for (const key in state.form) {
                        formData.append(key, state.form[key]);
                    }
                    formData.append('action', state.modalMode === 'create' ? 'create' : 'update');

                    const response = await fetch('ReservaServlet', {
                        method: 'POST',
                        body: formData
                    });

                    const {success, message, result} = await response.json();
                    if (!success)
                        throw new Error(message || 'Error al guardar la reserva.');

                    // Actualiza lista local
                    if (state.modalMode === 'create') {
                        state.reservas.push(result);
                    } else {
                        const index = state.reservas.findIndex(r => r.idReserva === state.form.idReserva);
                        if (index !== -1)
                            state.reservas[index] = result;
                    }

                    state.modalInstance.hide();
                } catch (error) {
                    state.messageError = error.message;
                }
            };

            // Eliminar reserva
            const deleteReserva = async (idReserva) => {
                if (!confirm('¿Deseas eliminar esta reserva?'))
                    return;

                try {
                    const formData = new FormData();
                    formData.append('action', 'delete');
                    formData.append('id', idReserva);

                    const response = await fetch('ReservaServlet', {method: 'POST', body: formData});
                    const {success, message} = await response.json();

                    if (!success)
                        throw new Error(message || 'Error al eliminar reserva.');

                    state.reservas = state.reservas.filter(r => r.idReserva !== idReserva);
                } catch (error) {
                    alert(error.message);
                }
            };

            // Obtener reservas
            const getReservations = async () => {
                state.messageError = null;

                try {
                    const response = await fetch('ReservaServlet?action=', {
                        method: 'GET'
                    });

                    if (!response.ok) {
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

            onMounted(async () => {
                getReservations();
            });

            return {
                state,
                openModal,
                saveReserva,
                deleteReserva
            };
        }
    }).mount('#app');
</script>

<%@include file="../includes/footer.jsp" %>
