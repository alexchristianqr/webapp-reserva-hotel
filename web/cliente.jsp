<%@include file="../includes/header.jsp" %>

<header class="d-flex justify-content-between align-items-center mb-4">
    <div class="d-flex align-items-center">
        <a href="home.jsp" class="btn btn-outline-secondary me-3">
            <i class="bi bi-arrow-left"></i> Volver
        </a>
        <h1><i class="bi bi-people-fill"></i> Gestión de Clientes</h1>
    </div>
    <button class="btn btn-primary" @click="openCreateModal">
        <i class="bi bi-plus-circle"></i> Agregar Nuevo Cliente
    </button>
</header>
<main>
    <div class="card shadow-sm">
        <div class="card-body">
            <table class="table table-hover align-middle">
                <thead class="table-light">
                    <tr>
                        <th>#</th>
                        <th>Nombres</th>
                        <th>Apellidos</th>
                        <th>Nro. Documento</th>
                        <th>Teléfono</th>
                        <th>Estado</th>
                        <th>Acciones</th>
                    </tr>
                </thead>
                <tbody>
                    <tr v-if="state.clients.length === 0">
                        <td colspan="7" class="text-center text-muted">No hay clientes registrados.</td>
                    </tr>
                    <tr v-for="(client, index) in state.clients" :key="client.idCliente">
                        <td>{{ index + 1 }}</td>
                        <td>{{ client.nombre }}</td>
                        <td>{{ client.apellidos }}</td>
                        <td>{{ client.nroDocumento }}</td>
                        <td>{{ client.telefono }}</td>
                        <td><span class="badge" :class="client.estado === 'activo' ? 'bg-success' : 'bg-secondary'">{{ client.estado }}</span></td>
                        <td>
                            <button class="btn btn-sm btn-outline-primary me-2" @click="openEditModal(client)">
                                <i class="bi bi-pencil-square"></i> Editar
                            </button>
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>
    </div>

    <div class="modal fade" id="clientModal" tabindex="-1" aria-labelledby="modalLabel" aria-hidden="true">
        <div class="modal-dialog modal-lg">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="modalLabel">{{ state.isEditing ? 'Editar Cliente' : 'Agregar Nuevo Cliente' }}</h5>
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
                    <form @submit.prevent="saveClient">
                        <div class="row">
                            <div class="col-md-6 mb-3">
                                <label for="nombre" class="form-label">Nombres</label>
                                <input v-model="state.clientInForm.nombre" type="text" class="form-control" id="nombre" required>
                            </div>
                            <div class="col-md-6 mb-3">
                                <label for="apellidos" class="form-label">Apellidos</label>
                                <input v-model="state.clientInForm.apellidos" type="text" class="form-control" id="apellidos" required>
                            </div>
                        </div>
                        <div class="row">
                            <div class="col-md-6 mb-3">
                                <label for="tipoDocumento" class="form-label">Tipo Documento</label>
                                <select v-model="state.clientInForm.tipoDocumento" class="form-select" id="tipoDocumento">
                                    <option value="1">DNI</option>
                                    <option value="2">Pasaporte</option>
                                </select>
                            </div>
                            <div class="col-md-6 mb-3">
                                <label for="nroDocumento" class="form-label">Nro. Documento</label>
                                <input v-model="state.clientInForm.nroDocumento" type="text" class="form-control" id="nroDocumento" required>
                            </div>
                        </div>
                        <div class="row">
                            <div class="col-md-4 mb-3">
                                <label for="edad" class="form-label">Edad</label>
                                <input v-model="state.clientInForm.edad" type="number" class="form-control" id="edad">
                            </div>
                            <div class="col-md-4 mb-3">
                                <label for="sexo" class="form-label">Sexo</label>
                                <select v-model="state.clientInForm.sexo" class="form-select" id="sexo">
                                    <option value="M">Masculino</option>
                                    <option value="F">Femenino</option>
                                </select>
                            </div>
                            <div class="col-md-4 mb-3">
                                <label for="telefono" class="form-label">Teléfono</label>
                                <input v-model="state.clientInForm.telefono" type="text" class="form-control" id="telefono">
                            </div>
                        </div>
                        <div class="modal-footer">
                            <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancelar</button>
                            <button type="submit" class="btn btn-primary">{{ state.isEditing ? 'Guardar Cambios' : 'Crear Cliente' }}</button>
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
                clients: [],
                clientInForm: { tipoDocumento: 1, sexo: 'Masculino' },
                isEditing: false,
                messageError: null,
                messageSuccess: null,
            });

            const clientModal = ref(null);

            onMounted(() => {
                clientModal.value = new bootstrap.Modal(document.getElementById('clientModal'));
                fetchClients();
            });

            const fetchClients = async () => {
                try {
                    console.log("1. Intentando buscar clientes...");
                    const response = await fetch('/webapp-reserva-hotel/clientes?action=listar');
                    console.log("2. Respuesta del servidor recibida:", response);
                    if (!response.ok) throw new Error('Error de red, estado: ' + response.status);
                    
                    const data = await response.json();
                    console.log("3. Datos convertidos a JSON:", data);

                    if(data.success) {
                        console.log("4. Asignando resultado a la lista:", data.result);
                        state.clients = data.result;
                    } else {
                        throw new Error(data.message);
                    }
                } catch (error) {
                    console.error("ERROR en fetchClients:", error);
                    state.messageError = 'Error de conexión: ' + error.message;
                }
            };
            
            const openCreateModal = () => {
                state.isEditing = false;
                state.clientInForm = { tipoDocumento: 1, sexo: 'M' };

                // ### LÍNEAS AÑADIDAS ###
                // Limpia los mensajes de error o éxito antes de mostrar el modal.
                state.messageError = null;
                state.messageSuccess = null;
                // ### FIN DEL CAMBIO ###

                clientModal.value.show();
            };

            const openEditModal = (client) => {
                state.isEditing = true;
                state.clientInForm = { ...client };

                // ### LÍNEAS AÑADIDAS ###
                // Limpia los mensajes de error o éxito antes de mostrar el modal.
                state.messageError = null;
                state.messageSuccess = null;
                // ### FIN DEL CAMBIO ###

                clientModal.value.show();
            };

            const saveClient = async () => {
                const action = state.isEditing ? 'actualizar' : 'crear';
                const formData = new FormData();

                // ### INICIO DEL CAMBIO ###
                // 1. Añadimos la acción como un campo más del formulario.
                formData.append('action', action);
                // ### FIN DEL CAMBIO ###

                // Añadimos el resto de los datos del formulario al FormData.
                for(const key in state.clientInForm) {
                    formData.append(key, state.clientInForm[key]);
                }

                try {
                    // ### INICIO DEL CAMBIO ###
                    // 2. La URL ahora está limpia, sin parámetros.
                    const response = await fetch('/webapp-reserva-hotel/clientes', {
                        method: 'POST',
                        body: formData
                    });
                    // ### FIN DEL CAMBIO ###

                    if (!response.ok) throw new Error('Error de red al guardar');

                    const data = await response.json();
                    if(data.success) {
                        state.messageSuccess = data.message;
                        //clientModal.value.hide();
                        fetchClients();
                        
                        if (!state.isEditing) {
                            clientModal.value.hide();
                        }
                        
                    } else {
                        // Ahora veremos el error específico del backend si algo falla
                        throw new Error(data.message || "Error desconocido en el servidor");
                    }
                } catch (error) {
                    state.messageError = 'Error al guardar: ' + error.message;
                }
            };

            return {
                state,
                openCreateModal,
                openEditModal,
                saveClient
            };
        }
    }).mount('#app');
</script>

<%@include file="../includes/footer.jsp" %>