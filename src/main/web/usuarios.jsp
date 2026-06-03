<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@include file="includes/header.jsp" %>

<header class="py-3 border-bottom mb-4">
    <div class="d-flex justify-content-between align-items-center mb-4">
        <h2 class="mb-0">Gestión de Usuarios</h2>
        <div class="d-flex gap-2">
            <a href="/webapp-reserva-hotel/configuraciones.jsp" class="btn btn-outline-secondary">
                <i class="bi bi-caret-left"></i> Volver
            </a>
            <button class="btn btn-primary mr-5" @click="openCreateModal()">Nuevo Usuario</button>
        </div>
    </div>
    <div class="row g-2 align-items-center">
        <div class="col-md-6">
            <div class="input-group">
                <span class="input-group-text"><i class="bi bi-search"></i></span>
                <input v-model="state.buscar" @input="onBuscarInput" type="text" class="form-control"
                       placeholder="Buscar por nombres, apellidos o usuario...">
                <button v-if="state.buscar" class="btn btn-outline-secondary" @click="limpiarBusqueda" title="Limpiar">
                    <i class="bi bi-x-lg"></i>
                </button>
            </div>
        </div>
        <div class="col-md-6 text-md-end">
            <span class="badge bg-secondary fs-6">{{ state.usuarios.length }} registro(s)</span>
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
                <th>Usuario</th>
                <th>Rol</th>
                <th>Estado</th>
                <th>Acciones</th>
            </tr>
        </thead>
        <tbody>
            <tr v-if="state.usuarios.length === 0">
                <td colspan="7" class="text-center text-muted">No hay usuarios registrados.</td>
            </tr>
            <tr v-for="(usuario, index) in state.usuarios" :key="usuario.idUsuario">
                <td>{{ index + 1 }}</td>
                <td>{{ usuario.nombres }}</td>
                <td>{{ usuario.apellidos }}</td>
                <td>{{ usuario.username }}</td>
                <td><span class="badge bg-info text-dark">{{ usuario.rol }}</span></td>
                <td><span class="badge" :class="usuario.estado === 'activo' ? 'bg-success' : 'bg-secondary'">{{ usuario.estado }}</span></td>
                <td>
                    <button class="btn btn-sm btn-primary me-2" title="Editar" @click="openEditModal(usuario)">
                        <i class="bi bi-pencil-square"></i>
                    </button>
                    <button class="btn btn-sm btn-danger" title="Eliminar" @click="eliminarUsuario(usuario)"
                            :disabled="usuario.estado !== 'activo'">
                        <i class="bi bi-trash"></i>
                    </button>
                </td>
            </tr>
        </tbody>
    </table>

    <!-- Modal -->
    <div class="modal fade" id="usuarioModal" tabindex="-1" aria-labelledby="modalLabel" aria-hidden="true">
        <div class="modal-dialog modal-lg">
            <div class="modal-content">
                <form @submit.prevent="guardarUsuario">

                    <div class="modal-header">
                        <h5 class="modal-title" id="modalLabel">{{ state.isEditing ? 'Editar Usuario' : 'Nuevo Usuario' }}</h5>
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
                                <label for="nombres" class="form-label">Nombres</label>
                                <input v-model="state.usuarioInForm.nombres" type="text" class="form-control" id="nombres" required>
                            </div>
                            <div class="col-md-6 mb-3">
                                <label for="apellidos" class="form-label">Apellidos</label>
                                <input v-model="state.usuarioInForm.apellidos" type="text" class="form-control" id="apellidos" required>
                            </div>
                        </div>
                        <div class="row">
                            <div class="col-md-6 mb-3">
                                <label for="rol" class="form-label">Rol</label>
                                <select v-model="state.usuarioInForm.rol" class="form-select" id="rol" required>
                                    <option value="empleado">Empleado</option>
                                    <option value="cliente">Cliente</option>
                                </select>
                            </div>
                            <div class="col-md-6 mb-3">
                                <label for="username" class="form-label">Usuario (correo)</label>
                                <input v-model="state.usuarioInForm.username" type="email" class="form-control" id="username" required>
                            </div>
                        </div>
                        <div class="row">
                            <div class="col-md-6 mb-3" v-if="!state.isEditing">
                                <label for="password" class="form-label">Contraseña</label>
                                <input v-model="state.usuarioInForm.password" type="password" class="form-control" id="password" required>
                            </div>
                            <div class="col-md-6 mb-3" v-if="state.isEditing">
                                <label for="estado" class="form-label">Estado</label>
                                <select v-model="state.usuarioInForm.estado" class="form-select" id="estado">
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
</main>

<script>
    const {createApp, reactive, onMounted, ref} = Vue;
    const redirectLogin = '/webapp-reserva-hotel/login.jsp';

    createApp({
        setup() {
            const state = reactive({
                usuarios: [],
                usuarioInForm: {rol: 'empleado'},
                isEditing: false,
                buscar: '',
                messageError: null,
                messageSuccess: null,
            });

            const usuarioModal = ref(null);
            let buscarTimer = null;

            const listarUsuarios = async () => {
                try {
                    const url = '/webapp-reserva-hotel/UsuarioServlet?action=listar&buscar=' + encodeURIComponent(state.buscar);
                    const response = await fetch(url);

                    if (!response.ok) {
                        if (response.status === 401) {
                            window.location.href = redirectLogin;
                            return;
                        }
                        throw new Error('Error de red, estado: ' + response.status);
                    }

                    const data = await response.json();
                    state.usuarios = data.success ? data.result : [];
                } catch (error) {
                    console.error("ERROR en listarUsuarios:", error);
                    state.usuarios = [];
                }
            };

            const onBuscarInput = () => {
                clearTimeout(buscarTimer);
                buscarTimer = setTimeout(listarUsuarios, 350);
            };

            const limpiarBusqueda = () => {
                state.buscar = '';
                listarUsuarios();
            };

            const openCreateModal = () => {
                state.isEditing = false;
                state.usuarioInForm = {rol: 'empleado'};
                state.messageError = null;
                state.messageSuccess = null;
                usuarioModal.value.show();
            };

            const openEditModal = (usuario) => {
                state.isEditing = true;
                state.usuarioInForm = {...usuario};
                state.messageError = null;
                state.messageSuccess = null;
                usuarioModal.value.show();
            };

            const guardarUsuario = async () => {
                const action = state.isEditing ? 'actualizar' : 'crear';
                const formData = new FormData();
                formData.append('action', action);

                for (const key in state.usuarioInForm) {
                    formData.append(key, state.usuarioInForm[key]);
                }

                try {
                    const response = await fetch('/webapp-reserva-hotel/UsuarioServlet', {
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
                        listarUsuarios();
                        if (!state.isEditing) {
                            usuarioModal.value.hide();
                        }
                    } else {
                        throw new Error(data.message || "Error desconocido en el servidor");
                    }
                } catch (error) {
                    state.messageError = 'Error al guardar: ' + error.message;
                }
            };

            const eliminarUsuario = async (usuario) => {
                if (!confirm('¿Deseas desactivar al usuario "' + usuario.username + '"?'))
                    return;

                const formData = new FormData();
                formData.append('action', 'eliminar');
                formData.append('idUsuario', usuario.idUsuario);

                try {
                    const response = await fetch('/webapp-reserva-hotel/UsuarioServlet', {
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
                        listarUsuarios();
                    } else {
                        throw new Error(data.message || "Error al eliminar");
                    }
                } catch (error) {
                    alert(error.message);
                }
            };

            onMounted(async () => {
                usuarioModal.value = new bootstrap.Modal(document.getElementById('usuarioModal'));
                await listarUsuarios();
            });

            return {
                state,
                onBuscarInput,
                limpiarBusqueda,
                openCreateModal,
                openEditModal,
                guardarUsuario,
                eliminarUsuario
            };
        }
    }).mount('#app');
</script>

<%@include file="includes/footer.jsp" %>
