<%@include file="../includes/header.jsp" %>

<header class="d-flex justify-content-between align-items-center mb-4">
    <div class="d-flex align-items-center">
        <a href="home.jsp" class="btn btn-outline-secondary me-3">
            <i class="bi bi-arrow-left"></i> Volver
        </a>
        <h1><i class="bi bi-door-closed-fill"></i> Gestión de Habitaciones</h1>
    </div>
    <button class="btn btn-primary" @click="openCreateModal">
        <i class="bi bi-plus-circle"></i> Agregar Nueva Habitación
    </button>
</header>

<main>
    <div class="card shadow-sm">
        <div class="card-body">
            <table class="table table-hover align-middle">
                <thead class="table-light">
                    <tr>
                        <th>#</th>
                        <th>Tipo de Habitación</th>
                        <th>Número</th>
                        <th>Precio (S/)</th>
                        <th>Estado</th>
                        <th>Acciones</th>
                    </tr>
                </thead>
                <tbody>
                    <tr v-if="state.rooms.length === 0">
                        <td colspan="6" class="text-center text-muted">No hay habitaciones registradas.</td>
                    </tr>
                    <tr v-for="(room, index) in state.rooms" :key="room.idHabitacion">
                        <td>{{ index + 1 }}</td>
                        <td>{{ room.tipo }}</td>
                        <td>{{ room.numero }}</td>
                        <td>{{ room.precio }}</td>
                        <td>
                            <span class="badge" :class="room.estado === 'disponible' ? 'bg-success' : 'bg-secondary'">
                                {{ room.estado }}
                            </span>
                        </td>
                        <td>
                            <button class="btn btn-sm btn-outline-primary me-2" @click="openEditModal(room)">
                                <i class="bi bi-pencil-square"></i> Editar
                            </button>
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>
    </div>

    <!-- Modal -->
    <div class="modal fade" id="roomModal" tabindex="-1" aria-labelledby="modalLabel" aria-hidden="true">
        <div class="modal-dialog modal-lg">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="modalLabel">{{ state.isEditing ? 'Editar Habitación' : 'Agregar Nueva Habitación' }}</h5>
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

                    <form @submit.prevent="saveRoom">
                        <div class="row">
                            <div class="col-md-6 mb-3">
                                <label for="tipo" class="form-label">Tipo de Habitación</label>
                                <select v-model="state.roomInForm.tipo" class="form-select" id="tipo" required>
                                    <option value="Simple">Simple</option>
                                    <option value="Doble">Doble</option>
                                    <option value="Matrimonial">Matrimonial</option>
                                </select>
                            </div>
                            <div class="col-md-6 mb-3">
                                <label for="numero" class="form-label">Número de Habitación</label>
                                <input v-model="state.roomInForm.numero" type="text" class="form-control" id="numero" required>
                            </div>
                        </div>

                        <div class="row">
                            <div class="col-md-6 mb-3">
                                <label for="precio" class="form-label">Precio por noche (S/)</label>
                                <input v-model="state.roomInForm.precio" type="number" step="0.01" class="form-control" id="precio" required>
                            </div>
                            <div class="col-md-6 mb-3">
                                <label for="estado" class="form-label">Estado</label>
                                <select v-model="state.roomInForm.estado" class="form-select" id="estado" required>
                                    <option value="disponible">Disponible</option>
                                    <option value="ocupado">Ocupado</option>
                                </select>
                            </div>
                        </div>

                        <div class="modal-footer">
                            <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancelar</button>
                            <button type="submit" class="btn btn-primary">{{ state.isEditing ? 'Guardar Cambios' : 'Crear Habitación' }}</button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>
</main>

<script>
    const { createApp, reactive, onMounted, ref } = Vue;

    createApp({
        setup() {
            const state = reactive({
                rooms: [],
                roomInForm: { tipo: 'Simple', estado: 'disponible' },
                isEditing: false,
                messageError: null,
                messageSuccess: null,
            });

            const roomModal = ref(null);

            onMounted(() => {
                roomModal.value = new bootstrap.Modal(document.getElementById('roomModal'));
                fetchRooms();
            });

            const fetchRooms = async () => {
                try {
                    const response = await fetch('/webapp-reserva-hotel/habitaciones?action=listar');
                    if (!response.ok) throw new Error('Error al obtener habitaciones');
                    const data = await response.json();
                    if (data.success) {
                        state.rooms = data.result;
                    } else {
                        throw new Error(data.message);
                    }
                } catch (error) {
                    state.messageError = 'Error al cargar habitaciones: ' + error.message;
                }
            };

            const openCreateModal = () => {
                state.isEditing = false;
                state.roomInForm = { tipo: 'Simple', estado: 'disponible' };
                state.messageError = null;
                state.messageSuccess = null;
                roomModal.value.show();
            };

            const openEditModal = (room) => {
                state.isEditing = true;
                state.roomInForm = { ...room };
                state.messageError = null;
                state.messageSuccess = null;
                roomModal.value.show();
            };

            const saveRoom = async () => {
                const action = state.isEditing ? 'actualizar' : 'crear';
                const formData = new FormData();
                formData.append('action', action);
                for (const key in state.roomInForm) {
                    formData.append(key, state.roomInForm[key]);
                }

                try {
                    const response = await fetch('/webapp-reserva-hotel/habitaciones', {
                        method: 'POST',
                        body: formData
                    });

                    if (!response.ok) throw new Error('Error al guardar la habitación');
                    const data = await response.json();

                    if (data.success) {
                        state.messageSuccess = data.message;
                        fetchRooms();
                        if (!state.isEditing) roomModal.value.hide();
                    } else {
                        throw new Error(data.message);
                    }
                } catch (error) {
                    state.messageError = 'Error al guardar: ' + error.message;
                }
            };

            return {
                state,
                openCreateModal,
                openEditModal,
                saveRoom
            };
        }
    }).mount('#app');
</script>

<%@include file="../includes/footer.jsp" %>
