<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@include file="includes/header.jsp" %>

<header class="py-3 border-bottom mb-4">
    <div class="d-flex justify-content-between align-items-center mb-4">
        <h2 class="mb-0">Gesti�n de Clientes</h2>
        <div class="d-flex gap-2">
            <a href="/webapp-reserva-hotel/configuraciones.jsp" class="btn btn-outline-secondary">
                <i class="bi bi-caret-left"></i> Volver
            </a>
            <button class="btn btn-primary mr-5" @click="openCreateModal()">Nuevo Cliente</button>
        </div>
    </div>
    <div class="row g-2 align-items-center">
        <div class="col-md-6">
            <div class="input-group">
                <span class="input-group-text"><i class="bi bi-search"></i></span>
                <input v-model="state.buscar" @input="onBuscarInput" type="text" class="form-control"
                       placeholder="Buscar por nombre, apellido o documento...">
                <button v-if="state.buscar" class="btn btn-outline-secondary" @click="limpiarBusqueda" title="Limpiar">
                    <i class="bi bi-x-lg"></i>
                </button>
            </div>
        </div>
        <div class="col-md-6 text-md-end">
            <span class="badge bg-secondary fs-6">{{ state.clients.length }} registro(s)</span>
        </div>
    </div>
</header>

<main class="flex-fill">
    <table class="table table-hover table-bordered align-middle">
        <thead class="table-light">
            <tr>
                <th>#</th>
                <th>Nombres</th>
                <th>Apellidos</th>
                <th>Nro. Documento</th>
                <th>Tel�fono</th>
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
                    <button class="btn btn-sm btn-primary me-2" title="Editar" @click="openEditModal(client)">
                        <i class="bi bi-pencil-square"></i>
                    </button>
                    <button class="btn btn-sm btn-danger" title="Eliminar" @click="eliminarCliente(client)"
                            :disabled="client.estado !== 'activo'">
                        <i class="bi bi-trash"></i>
                    </button>
                </td>
            </tr>
        </tbody>
    </table>

    <div class="modal fade" id="clientModal" tabindex="-1" aria-labelledby="modalLabel" aria-hidden="true">
        <div class="modal-dialog modal-lg">
            <div class="modal-content">
                <form @submit.prevent="saveClient">

                    <div class="modal-header">
                        <h5 class="modal-title" id="modalLabel">{{ state.isEditing ? 'Editar Cliente' : 'Nuevo Cliente' }}</h5>
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
                                <label for="telefono" class="form-label">Tel&eacute;fono</label>
                                <input v-model="state.clientInForm.telefono" type="text" class="form-control" id="telefono">
                            </div>
                        </div>

                        <hr>
                        <p class="text-muted small mb-2"><i class="bi bi-person-lock me-1"></i>Cuenta de acceso del cliente</p>
                        <div class="row">
                            <div class="col-md-6 mb-3">
                                <label for="username" class="form-label">Correo (usuario)</label>
                                <input v-model="state.clientInForm.username" type="email" class="form-control" id="username"
                                       :readonly="state.isEditing" :required="!state.isEditing">
                            </div>
                            <div class="col-md-6 mb-3" v-if="!state.isEditing">
                                <label for="password" class="form-label">Contrase&ntilde;a</label>
                                <input v-model="state.clientInForm.password" type="password" class="form-control" id="password" required>
                            </div>
                            <div class="col-md-6 mb-3" v-if="state.isEditing">
                                <label for="estado" class="form-label">Estado</label>
                                <select v-model="state.clientInForm.estado" class="form-select" id="estado">
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
                        <i class="bi bi-exclamation-triangle me-2"></i>Confirmar baja de cliente
                    </h5>
                    <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body" v-if="state.clientToDelete">
                    <div v-if="state.deleteError" class="alert alert-danger alert-dismissible fade show" role="alert">
                        {{ state.deleteError }}
                        <button type="button" class="btn-close" @click="state.deleteError = null" aria-label="Close"></button>
                    </div>

                    <p>¿Deseas dar de baja al siguiente cliente?</p>
                    <ul class="list-group mb-3">
                        <li class="list-group-item d-flex justify-content-between">
                            <strong>Nombres</strong>
                            <span>{{ state.clientToDelete.nombre }} {{ state.clientToDelete.apellidos }}</span>
                        </li>
                        <li class="list-group-item d-flex justify-content-between">
                            <strong>Nro. Documento</strong>
                            <span>{{ state.clientToDelete.nroDocumento }}</span>
                        </li>
                        <li class="list-group-item d-flex justify-content-between">
                            <strong>Teléfono</strong>
                            <span>{{ state.clientToDelete.telefono || '-' }}</span>
                        </li>
                    </ul>
                    <p class="text-muted small mb-0">
                        El cliente pasará a estado <span class="badge bg-secondary">inactivo</span> y no podrá
                        ser usado en nuevas reservas. Sus datos e historial no se eliminan.
                    </p>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">No, cancelar</button>
                    <button type="button" class="btn btn-danger" @click="confirmarEliminarCliente">
                        <i class="bi bi-trash"></i> Sí, dar de baja
                    </button>
                </div>
            </div>
        </div>
    </div>
</main>

<script>
    const {createApp, reactive, onMounted, ref} = Vue;
    const redirectLogin = '/webapp-reserva-hotel/login.jsp';

    createApp({
        setup() {
            const state = reactive({
                clients: [],
                clientInForm: {tipoDocumento: 1, sexo: 'M'},
                isEditing: false,
                buscar: '',
                messageError: null,
                messageSuccess: null,
                clientToDelete: null,
                deleteError: null,
            });

            const clientModal = ref(null);
            const deleteModal = ref(null);
            let buscarTimer = null;

            const onBuscarInput = () => {
                clearTimeout(buscarTimer);
                buscarTimer = setTimeout(fetchClients, 350);
            };

            const limpiarBusqueda = () => {
                state.buscar = '';
                fetchClients();
            };

            const fetchClients = async () => {
                try {
                    const url = '/webapp-reserva-hotel/ClienteServlet?action=listar&buscar=' + encodeURIComponent(state.buscar);
                    const response = await fetch(url);

                    if (!response.ok) {
                        if (response.status === 401) {
                            window.location.href = redirectLogin;
                            return;
                        }
                        throw new Error('Error de red, estado: ' + response.status);
                    }

                    const data = await response.json();

                    state.clients = data.success ? data.result : [];
                } catch (error) {
                    console.error("ERROR en fetchClients:", error);
                    state.clients = [];
                    state.messageError = 'Error de conexi�n: ' + error.message;
                }
            };

            const openCreateModal = () => {
                state.isEditing = false;
                state.clientInForm = {tipoDocumento: 1, sexo: 'M'};

                // ### L�NEAS A�ADIDAS ###
                // Limpia los mensajes de error o �xito antes de mostrar el modal.
                state.messageError = null;
                state.messageSuccess = null;
                // ### FIN DEL CAMBIO ###

                clientModal.value.show();
            };

            const openEditModal = (client) => {
                state.isEditing = true;
                state.clientInForm = {...client};

                // ### L�NEAS A�ADIDAS ###
                // Limpia los mensajes de error o �xito antes de mostrar el modal.
                state.messageError = null;
                state.messageSuccess = null;
                // ### FIN DEL CAMBIO ###

                clientModal.value.show();
            };

            const saveClient = async () => {
                const action = state.isEditing ? 'actualizar' : 'crear';
                const formData = new FormData();

                // ### INICIO DEL CAMBIO ###
                // 1. A�adimos la acci�n como un campo m�s del formulario.
                formData.append('action', action);
                // ### FIN DEL CAMBIO ###

                // A�adimos el resto de los datos del formulario al FormData.
                for (const key in state.clientInForm) {
                    formData.append(key, state.clientInForm[key]);
                }

                try {
                    // ### INICIO DEL CAMBIO ###
                    // 2. La URL ahora est� limpia, sin par�metros.
                    const response = await fetch('/webapp-reserva-hotel/ClienteServlet', {
                        method: 'POST',
                        body: formData
                    });
                    // ### FIN DEL CAMBIO ###

                    if (!response.ok) {
                        if (response.status === 401) {
                            window.location.href = redirectLogin;
                            return;
                        }
                        throw new Error('Error de red al guardar');
                    }

                    const data = await response.json();
                    if (data.success) {
                        state.messageSuccess = data.message;
                        //clientModal.value.hide();
                        fetchClients();

                        if (!state.isEditing) {
                            clientModal.value.hide();
                        }

                    } else {
                        // Ahora veremos el error espec�fico del backend si algo falla
                        throw new Error(data.message || "Error desconocido en el servidor");
                    }
                } catch (error) {
                    state.messageError = 'Error al guardar: ' + error.message;
                }
            };

            // Abre el modal de confirmación con el detalle del cliente a dar de baja.
            const eliminarCliente = (client) => {
                state.clientToDelete = client;
                state.deleteError = null;
                deleteModal.value.show();
            };

            // Ejecuta la baja solo cuando el usuario confirma en el modal.
            const confirmarEliminarCliente = async () => {
                const client = state.clientToDelete;
                if (!client)
                    return;

                const formData = new FormData();
                formData.append('action', 'eliminar');
                formData.append('idCliente', client.idCliente);

                try {
                    const response = await fetch('/webapp-reserva-hotel/ClienteServlet', {
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
                        state.clientToDelete = null;
                        fetchClients();
                    } else {
                        throw new Error(data.message || "Error al eliminar");
                    }
                } catch (error) {
                    state.deleteError = error.message;
                }
            };

            onMounted(async () => {
                clientModal.value = new bootstrap.Modal(document.getElementById('clientModal'));
                deleteModal.value = new bootstrap.Modal(document.getElementById('deleteModal'));
                await fetchClients();
            });

            return {
                state,
                onBuscarInput,
                limpiarBusqueda,
                openCreateModal,
                openEditModal,
                saveClient,
                eliminarCliente,
                confirmarEliminarCliente
            };
        }
    }).mount('#app');
</script>

<%@include file="includes/footer.jsp" %>