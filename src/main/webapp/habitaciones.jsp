<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@include file="includes/header.jsp" %>

<header class="py-3 border-bottom mb-4">
    <div class="d-flex justify-content-between align-items-center mb-4">
        <h2 class="mb-0">Gestión de Habitaciones</h2>
        <div class="d-flex gap-2">
            <a href="${pageContext.request.contextPath}/configuraciones.jsp" class="btn btn-outline-secondary">
                <i class="bi bi-caret-left"></i> Volver
            </a>
            <button class="btn btn-primary mr-5" @click="openCreateModal()">Nueva Habitación</button>
        </div>
    </div>
    <div class="row g-2 align-items-center">
        <div class="col-md-6">
            <div class="input-group">
                <span class="input-group-text"><i class="bi bi-search"></i></span>
                <input v-model="state.buscar" @input="onBuscarInput" type="text" class="form-control"
                       placeholder="Buscar por descripción, número o tipo...">
                <button v-if="state.buscar" class="btn btn-outline-secondary" @click="limpiarBusqueda" title="Limpiar">
                    <i class="bi bi-x-lg"></i>
                </button>
            </div>
        </div>
        <div class="col-md-6 text-md-end">
            <span class="badge bg-secondary fs-6">{{ state.rooms.length }} registro(s)</span>
        </div>
    </div>
</header>

<main class="flex-fill">
    <table class="table table-hover table-bordered align-middle">
        <thead class="table-light">
            <tr>
                <th>#</th>
                <th>Tipo</th>
                <th>Descripción</th>
                <th>Nivel</th>
                <th>Número</th>
                <th>Precio (S/)</th>
                <th>Camas</th>
                <th>Estado</th>
                <th>Acciones</th>
            </tr>
        </thead>
        <tbody>
            <tr v-if="state.rooms.length === 0">
                <td colspan="9" class="text-center text-muted">No hay habitaciones registradas.</td>
            </tr>
            <tr v-for="(room, index) in state.rooms" :key="room.idHabitacion">
                <td>{{ index + 1 }}</td>
                <td>{{ room.tipoDescripcion }}</td>
                <td>{{ room.descripcion }}</td>
                <td>{{ room.nivel }}</td>
                <td>{{ room.numeroPiso }}</td>
                <td>{{ room.precio }}</td>
                <td>{{ room.cantidadCamas }}</td>
                <td>
                    <span class="badge" :class="room.estado === 'activo' ? 'bg-success' : 'bg-secondary'">
                        {{ room.estado }}
                    </span>
                </td>
                <td>
                    <button class="btn btn-sm btn-primary me-2" title="Editar" @click="openEditModal(room)">
                        <i class="bi bi-pencil-square"></i>
                    </button>
                    <button class="btn btn-sm btn-danger" title="Eliminar" @click="eliminarHabitacion(room)"
                            :disabled="room.estado !== 'activo'">
                        <i class="bi bi-trash"></i>
                    </button>
                </td>
            </tr>
        </tbody>
    </table>

    <!-- Modal -->
    <div class="modal fade" id="roomModal" tabindex="-1" aria-labelledby="modalLabel" aria-hidden="true">
        <div class="modal-dialog modal-lg">
            <div class="modal-content">
                <form @submit.prevent="guardarHabitacion">

                    <div class="modal-header">
                        <h5 class="modal-title" id="modalLabel">{{ state.isEditing ? 'Editar Habitación' : 'Nueva Habitación' }}</h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                    </div>

                    <div class="modal-body">
                        <div v-if="state.messageSuccess" class="alert alert-success alert-dismissible fade show" role="alert">
                            {{ state.messageSuccess }}
                            <button type="button" class="btn-close" @click="state.messageSuccess = null" aria-label="Close"></button>
                        </div>
                        <div v-if="state.messageError" class="alert alert-danger alert-dismissible fade show" role="alert">
                            {{ state.messageError }}
                            <button type="button" class="btn-close" @click="state.messageError = null" aria-label="Close"></button>
                        </div>

                        <div class="row">
                            <div class="col-md-6 mb-3">
                                <label for="tipo" class="form-label">Tipo de Habitación</label>
                                <select v-model="state.roomInForm.idTipoHabitacion" class="form-select" id="tipo" required>
                                    <option v-for="tipo in state.tipos" :value="tipo.id">{{ tipo.descripcion }}</option>
                                </select>
                            </div>
                            <div class="col-md-6 mb-3">
                                <label for="descripcion" class="form-label">Descripción</label>
                                <input v-model="state.roomInForm.descripcion" type="text" class="form-control" id="descripcion" required>
                            </div>
                        </div>

                        <div class="row">
                            <div class="col-md-4 mb-3">
                                <label for="nivel" class="form-label">Nivel</label>
                                <input v-model="state.roomInForm.nivel" type="text" class="form-control" id="nivel" required>
                            </div>
                            <div class="col-md-4 mb-3">
                                <label for="numero" class="form-label">Número de Habitación</label>
                                <input v-model="state.roomInForm.numeroPiso" type="text" class="form-control" id="numero" required>
                            </div>
                            <div class="col-md-4 mb-3">
                                <label for="cantidadCamas" class="form-label">Cantidad de camas</label>
                                <input v-model="state.roomInForm.cantidadCamas" type="number" min="1" class="form-control" id="cantidadCamas" required>
                            </div>
                        </div>

                        <div class="row">
                            <div class="col-md-6 mb-3">
                                <label for="precio" class="form-label">Precio por noche (S/)</label>
                                <input v-model="state.roomInForm.precio" type="number" step="0.01" class="form-control" id="precio" required>
                            </div>
                            <div class="col-md-6 mb-3" v-if="state.isEditing">
                                <label for="estado" class="form-label">Estado</label>
                                <select v-model="state.roomInForm.estado" class="form-select" id="estado" required>
                                    <option value="activo">Activo</option>
                                    <option value="inactivo">Inactivo</option>
                                </select>
                            </div>
                        </div>
                    </div>

                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancelar</button>
                        <button type="submit" class="btn btn-success">
                            {{ !state.isEditing ? 'Guardar' : 'Actualizar' }}
                        </button>
                    </div>

                </form>
            </div>
        </div>
    </div>

    <!-- Modal de confirmación de baja -->
    <div class="modal fade" id="deleteModal" tabindex="-1" aria-labelledby="deleteModalLabel" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered">
            <div class="modal-content">
                <div class="modal-header bg-danger text-white">
                    <h5 class="modal-title" id="deleteModalLabel">
                        <i class="bi bi-exclamation-triangle me-2"></i>Confirmar baja de habitación
                    </h5>
                    <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body" v-if="state.roomToDelete">
                    <div v-if="state.deleteError" class="alert alert-danger alert-dismissible fade show" role="alert">
                        {{ state.deleteError }}
                        <button type="button" class="btn-close" @click="state.deleteError = null" aria-label="Close"></button>
                    </div>

                    <p>¿Deseas dar de baja la siguiente habitación?</p>
                    <ul class="list-group mb-3">
                        <li class="list-group-item d-flex justify-content-between">
                            <strong>Habitación</strong>
                            <span>N° {{ state.roomToDelete.numeroPiso }} — Nivel {{ state.roomToDelete.nivel }}</span>
                        </li>
                        <li class="list-group-item d-flex justify-content-between">
                            <strong>Tipo</strong>
                            <span>{{ state.roomToDelete.tipoDescripcion }}</span>
                        </li>
                        <li class="list-group-item d-flex justify-content-between">
                            <strong>Descripción</strong>
                            <span>{{ state.roomToDelete.descripcion }}</span>
                        </li>
                        <li class="list-group-item d-flex justify-content-between">
                            <strong>Precio por noche</strong>
                            <span>S/ {{ state.roomToDelete.precio }}</span>
                        </li>
                    </ul>
                    <p class="text-muted small mb-0">
                        La habitación pasará a estado <span class="badge bg-secondary">inactivo</span> y
                        dejará de aparecer como disponible para nuevas reservas.
                    </p>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">No, cancelar</button>
                    <button type="button" class="btn btn-danger" @click="confirmarEliminarHabitacion">
                        <i class="bi bi-trash"></i> Sí, dar de baja
                    </button>
                </div>
            </div>
        </div>
    </div>
</main>

<script>
    const {createApp, reactive, onMounted, ref} = Vue;
    const redirectLogin = '${pageContext.request.contextPath}/login.jsp';

    createApp({
        setup() {
            const state = reactive({
                rooms: [],
                tipos: [],
                roomInForm: {estado: 'activo', cantidadCamas: 1},
                isEditing: false,
                buscar: '',
                messageError: null,
                messageSuccess: null,
                roomToDelete: null,
                deleteError: null,
            });
            const roomModal = ref(null);
            const deleteModal = ref(null);
            let buscarTimer = null;

            const formDefaults = () => ({
                idTipoHabitacion: state.tipos.length ? state.tipos[0].id : '',
                estado: 'activo',
                cantidadCamas: 1
            });

            const listarTipos = async () => {
                try {
                    const response = await fetch('${pageContext.request.contextPath}/HabitacionServlet?action=tipos');
                    if (!response.ok) {
                        if (response.status === 401) {
                            window.location.href = redirectLogin;
                            return;
                        }
                        return;
                    }
                    const data = await response.json();
                    state.tipos = data.success ? data.result : [];
                } catch (error) {
                    console.error("ERROR en listarTipos:", error);
                }
            };

            const onBuscarInput = () => {
                clearTimeout(buscarTimer);
                buscarTimer = setTimeout(listarHabitaciones, 350);
            };

            const limpiarBusqueda = () => {
                state.buscar = '';
                listarHabitaciones();
            };

            const listarHabitaciones = async () => {
                try {
                    const url = '${pageContext.request.contextPath}/HabitacionServlet?action=listar&buscar=' + encodeURIComponent(state.buscar);
                    const response = await fetch(url);

                    if (!response.ok) {
                        if (response.status === 401) {
                            window.location.href = redirectLogin;
                            return;
                        }
                        throw new Error('Error al obtener habitaciones');
                    }

                    const data = await response.json();
                    state.rooms = data.success ? data.result : [];
                } catch (error) {
                    console.error("ERROR en listarHabitaciones:", error);
                    state.rooms = [];
                }
            };

            const openCreateModal = () => {
                state.isEditing = false;
                state.roomInForm = formDefaults();
                state.messageError = null;
                state.messageSuccess = null;
                roomModal.value.show();
            };

            const openEditModal = (room) => {
                state.isEditing = true;
                state.roomInForm = {...room};
                state.messageError = null;
                state.messageSuccess = null;
                roomModal.value.show();
            };

            const guardarHabitacion = async () => {
                const action = state.isEditing ? 'actualizar' : 'crear';
                const f = state.roomInForm;
                const formData = new FormData();
                formData.append('action', action);
                if (state.isEditing) {
                    formData.append('idHabitacion', f.idHabitacion);
                    formData.append('estado', f.estado);
                }
                formData.append('idTipoHabitacion', f.idTipoHabitacion);
                formData.append('descripcion', f.descripcion);
                formData.append('nivel', f.nivel);
                formData.append('numero', f.numeroPiso);
                formData.append('precio', f.precio);
                formData.append('cantidadCamas', f.cantidadCamas);

                try {
                    const response = await fetch('${pageContext.request.contextPath}/HabitacionServlet', {
                        method: 'POST',
                        body: formData
                    });

                    if (!response.ok) {
                        if (response.status === 401) {
                            window.location.href = redirectLogin;
                            return;
                        }
                        throw new Error('Error al guardar la habitación');
                    }

                    const data = await response.json();
                    if (data.success) {
                        state.messageSuccess = data.message;
                        await listarHabitaciones();
                        if (!state.isEditing) {
                            roomModal.value.hide();
                        }
                    } else {
                        throw new Error(data.message || "Error desconocido en el servidor");
                    }
                } catch (error) {
                    state.messageError = 'Error al guardar: ' + error.message;
                }
            };

            // Abre el modal de confirmación con el detalle de la habitación a dar de baja.
            const eliminarHabitacion = (room) => {
                state.roomToDelete = room;
                state.deleteError = null;
                deleteModal.value.show();
            };

            // Ejecuta la baja solo cuando el usuario confirma en el modal.
            const confirmarEliminarHabitacion = async () => {
                const room = state.roomToDelete;
                if (!room)
                    return;

                const formData = new FormData();
                formData.append('action', 'eliminar');
                formData.append('idHabitacion', room.idHabitacion);

                try {
                    const response = await fetch('${pageContext.request.contextPath}/HabitacionServlet', {
                        method: 'POST',
                        body: formData
                    });

                    if (!response.ok) {
                        if (response.status === 401) {
                            window.location.href = redirectLogin;
                            return;
                        }
                        throw new Error('Error de red al eliminar');
                    }

                    const data = await response.json();
                    if (data.success) {
                        deleteModal.value.hide();
                        state.roomToDelete = null;
                        listarHabitaciones();
                    } else {
                        throw new Error(data.message || "Error al eliminar");
                    }
                } catch (error) {
                    state.deleteError = error.message;
                }
            };

            onMounted(async () => {
                roomModal.value = new bootstrap.Modal(document.getElementById('roomModal'));
                deleteModal.value = new bootstrap.Modal(document.getElementById('deleteModal'));
                await listarTipos();
                await listarHabitaciones();
            });

            return {
                state,
                onBuscarInput,
                limpiarBusqueda,
                openCreateModal,
                openEditModal,
                guardarHabitacion,
                eliminarHabitacion,
                confirmarEliminarHabitacion
            };
        }
    }).mount('#app');
</script>

<%@include file="includes/footer.jsp" %>
