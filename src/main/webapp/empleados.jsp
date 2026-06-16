<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@include file="includes/header.jsp" %>

<header class="py-3 border-bottom mb-4">
    <div class="d-flex justify-content-between align-items-center mb-4">
        <h2 class="mb-0">Gestión de Empleados</h2>
        <div class="d-flex gap-2">
            <a href="/webapp-reserva-hotel/configuraciones.jsp" class="btn btn-outline-secondary">
                <i class="bi bi-caret-left"></i> Volver
            </a>
            <button class="btn btn-primary mr-5" @click="openCreateModal()">Nuevo Empleado</button>
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
            <span class="badge bg-secondary fs-6">{{ state.empleados.length }} registro(s)</span>
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
                <th>Perfil</th>
                <th>Sueldo (S/)</th>
                <th>Estado</th>
                <th>Acciones</th>
            </tr>
        </thead>
        <tbody>
            <tr v-if="state.empleados.length === 0">
                <td colspan="8" class="text-center text-muted">No hay empleados registrados.</td>
            </tr>
            <tr v-for="(empleado, index) in state.empleados" :key="empleado.idEmpleado">
                <td>{{ index + 1 }}</td>
                <td>{{ empleado.nombre }}</td>
                <td>{{ empleado.apellidos }}</td>
                <td>{{ empleado.nroDocumento }}</td>
                <td>{{ nombrePerfil(empleado.idPerfil) }}</td>
                <td>{{ empleado.sueldo }}</td>
                <td><span class="badge" :class="empleado.estado === 'activo' ? 'bg-success' : 'bg-secondary'">{{ empleado.estado }}</span></td>
                <td>
                    <button class="btn btn-sm btn-primary me-2" title="Editar" @click="openEditModal(empleado)">
                        <i class="bi bi-pencil-square"></i>
                    </button>
                    <button class="btn btn-sm btn-danger" title="Eliminar" @click="eliminarEmpleado(empleado)"
                            :disabled="empleado.estado !== 'activo'">
                        <i class="bi bi-trash"></i>
                    </button>
                </td>
            </tr>
        </tbody>
    </table>

    <!-- Modal -->
    <div class="modal fade" id="empleadoModal" tabindex="-1" aria-labelledby="modalLabel" aria-hidden="true">
        <div class="modal-dialog modal-lg">
            <div class="modal-content">
                <form @submit.prevent="guardarEmpleado">

                    <div class="modal-header">
                        <h5 class="modal-title" id="modalLabel">{{ state.isEditing ? 'Editar Empleado' : 'Nuevo Empleado' }}</h5>
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
                                <input v-model="state.empleadoInForm.nombre" type="text" class="form-control" id="nombre" required>
                            </div>
                            <div class="col-md-6 mb-3">
                                <label for="apellidos" class="form-label">Apellidos</label>
                                <input v-model="state.empleadoInForm.apellidos" type="text" class="form-control" id="apellidos" required>
                            </div>
                        </div>
                        <div class="row">
                            <div class="col-md-6 mb-3">
                                <label for="tipoDocumento" class="form-label">Tipo Documento</label>
                                <select v-model="state.empleadoInForm.tipoDocumento" class="form-select" id="tipoDocumento">
                                    <option value="1">DNI</option>
                                    <option value="2">Pasaporte</option>
                                </select>
                            </div>
                            <div class="col-md-6 mb-3">
                                <label for="nroDocumento" class="form-label">Nro. Documento</label>
                                <input v-model="state.empleadoInForm.nroDocumento" type="text" class="form-control" id="nroDocumento" required>
                            </div>
                        </div>
                        <div class="row">
                            <div class="col-md-4 mb-3">
                                <label for="edad" class="form-label">Edad</label>
                                <input v-model="state.empleadoInForm.edad" type="number" class="form-control" id="edad">
                            </div>
                            <div class="col-md-4 mb-3">
                                <label for="sexo" class="form-label">Sexo</label>
                                <select v-model="state.empleadoInForm.sexo" class="form-select" id="sexo">
                                    <option value="M">Masculino</option>
                                    <option value="F">Femenino</option>
                                </select>
                            </div>
                            <div class="col-md-4 mb-3">
                                <label for="telefono" class="form-label">Teléfono</label>
                                <input v-model="state.empleadoInForm.telefono" type="text" class="form-control" id="telefono">
                            </div>
                        </div>
                        <div class="row">
                            <div class="col-md-6 mb-3">
                                <label for="idPerfil" class="form-label">Perfil</label>
                                <select v-model="state.empleadoInForm.idPerfil" class="form-select" id="idPerfil" required>
                                    <option v-for="perfil in state.perfiles" :value="perfil.id">{{ perfil.nombre }}</option>
                                </select>
                            </div>
                            <div class="col-md-6 mb-3">
                                <label for="sueldo" class="form-label">Sueldo (S/)</label>
                                <input v-model="state.empleadoInForm.sueldo" type="number" step="0.01" class="form-control" id="sueldo" required>
                            </div>
                        </div>
                        <hr>
                        <p class="text-muted small mb-2"><i class="bi bi-person-lock me-1"></i>Cuenta de acceso del empleado</p>
                        <div class="row">
                            <div class="col-md-6 mb-3">
                                <label for="username" class="form-label">Correo (usuario)</label>
                                <input v-model="state.empleadoInForm.username" type="email" class="form-control" id="username"
                                       :readonly="state.isEditing" :required="!state.isEditing">
                            </div>
                            <div class="col-md-6 mb-3" v-if="!state.isEditing">
                                <label for="password" class="form-label">Contrase&ntilde;a</label>
                                <input v-model="state.empleadoInForm.password" type="password" class="form-control" id="password" required>
                            </div>
                            <div class="col-md-6 mb-3" v-if="state.isEditing">
                                <label for="estado" class="form-label">Estado</label>
                                <select v-model="state.empleadoInForm.estado" class="form-select" id="estado">
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
                        <i class="bi bi-exclamation-triangle me-2"></i>Confirmar baja de empleado
                    </h5>
                    <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body" v-if="state.empleadoToDelete">
                    <div v-if="state.deleteError" class="alert alert-danger alert-dismissible fade show" role="alert">
                        {{ state.deleteError }}
                        <button type="button" class="btn-close" @click="state.deleteError = null" aria-label="Close"></button>
                    </div>

                    <p>¿Deseas dar de baja al siguiente empleado?</p>
                    <ul class="list-group mb-3">
                        <li class="list-group-item d-flex justify-content-between">
                            <strong>Nombres</strong>
                            <span>{{ state.empleadoToDelete.nombre }} {{ state.empleadoToDelete.apellidos }}</span>
                        </li>
                        <li class="list-group-item d-flex justify-content-between">
                            <strong>Nro. Documento</strong>
                            <span>{{ state.empleadoToDelete.nroDocumento }}</span>
                        </li>
                        <li class="list-group-item d-flex justify-content-between">
                            <strong>Perfil</strong>
                            <span>{{ nombrePerfil(state.empleadoToDelete.idPerfil) }}</span>
                        </li>
                    </ul>
                    <p class="text-muted small mb-0">
                        El empleado pasará a estado <span class="badge bg-secondary">inactivo</span>.
                        Sus datos no se eliminan y podrá reactivarse editándolo.
                    </p>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">No, cancelar</button>
                    <button type="button" class="btn btn-danger" @click="confirmarEliminarEmpleado">
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
                empleados: [],
                // Perfiles de empleado segun db_hotel.sql (tabla empleados_perfiles)
                perfiles: [
                    {id: 1, nombre: 'Administrador'},
                    {id: 2, nombre: 'Recepcionista'},
                    {id: 3, nombre: 'Personal de limpieza'}
                ],
                empleadoInForm: {tipoDocumento: 1, sexo: 'M', idPerfil: 1},
                isEditing: false,
                buscar: '',
                messageError: null,
                messageSuccess: null,
                empleadoToDelete: null,
                deleteError: null,
            });

            const empleadoModal = ref(null);
            const deleteModal = ref(null);
            let buscarTimer = null;

            const nombrePerfil = (idPerfil) => {
                const perfil = state.perfiles.find(p => p.id === idPerfil);
                return perfil ? perfil.nombre : '-';
            };

            const onBuscarInput = () => {
                clearTimeout(buscarTimer);
                buscarTimer = setTimeout(listarEmpleados, 350);
            };

            const limpiarBusqueda = () => {
                state.buscar = '';
                listarEmpleados();
            };

            const listarEmpleados = async () => {
                try {
                    const url = '/webapp-reserva-hotel/EmpleadoServlet?action=listar&buscar=' + encodeURIComponent(state.buscar);
                    const response = await fetch(url);

                    if (!response.ok) {
                        if (response.status === 401) {
                            window.location.href = redirectLogin;
                            return;
                        }
                        throw new Error('Error de red, estado: ' + response.status);
                    }

                    const data = await response.json();

                    if (data.success) {
                        state.empleados = data.result;
                    } else {
                        state.empleados = [];
                    }
                } catch (error) {
                    console.error("ERROR en listarEmpleados:", error);
                    state.messageError = 'Error de conexión: ' + error.message;
                }
            };

            const openCreateModal = () => {
                state.isEditing = false;
                state.empleadoInForm = {tipoDocumento: 1, sexo: 'M', idPerfil: 1};
                state.messageError = null;
                state.messageSuccess = null;
                empleadoModal.value.show();
            };

            const openEditModal = (empleado) => {
                state.isEditing = true;
                state.empleadoInForm = {...empleado};
                state.messageError = null;
                state.messageSuccess = null;
                empleadoModal.value.show();
            };

            const guardarEmpleado = async () => {
                const action = state.isEditing ? 'actualizar' : 'crear';
                const formData = new FormData();
                formData.append('action', action);

                for (const key in state.empleadoInForm) {
                    formData.append(key, state.empleadoInForm[key]);
                }

                try {
                    const response = await fetch('/webapp-reserva-hotel/EmpleadoServlet', {
                        method: 'POST',
                        body: formData
                    });

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
                        listarEmpleados();
                        if (!state.isEditing) {
                            empleadoModal.value.hide();
                        }
                    } else {
                        throw new Error(data.message || "Error desconocido en el servidor");
                    }
                } catch (error) {
                    state.messageError = 'Error al guardar: ' + error.message;
                }
            };

            // Abre el modal de confirmación con el detalle del empleado a dar de baja.
            const eliminarEmpleado = (empleado) => {
                state.empleadoToDelete = empleado;
                state.deleteError = null;
                deleteModal.value.show();
            };

            // Ejecuta la baja solo cuando el usuario confirma en el modal.
            const confirmarEliminarEmpleado = async () => {
                const empleado = state.empleadoToDelete;
                if (!empleado)
                    return;

                const formData = new FormData();
                formData.append('action', 'eliminar');
                formData.append('idEmpleado', empleado.idEmpleado);

                try {
                    const response = await fetch('/webapp-reserva-hotel/EmpleadoServlet', {
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
                        state.empleadoToDelete = null;
                        listarEmpleados();
                    } else {
                        throw new Error(data.message || "Error al eliminar");
                    }
                } catch (error) {
                    state.deleteError = error.message;
                }
            };

            onMounted(async () => {
                empleadoModal.value = new bootstrap.Modal(document.getElementById('empleadoModal'));
                deleteModal.value = new bootstrap.Modal(document.getElementById('deleteModal'));
                await listarEmpleados();
            });

            return {
                state,
                nombrePerfil,
                onBuscarInput,
                limpiarBusqueda,
                openCreateModal,
                openEditModal,
                guardarEmpleado,
                eliminarEmpleado,
                confirmarEliminarEmpleado
            };
        }
    }).mount('#app');
</script>

<%@include file="includes/footer.jsp" %>
