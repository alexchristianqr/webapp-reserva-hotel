<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@include file="includes/header.jsp" %>

<header class="py-3 border-bottom mb-4">
    <div class="d-flex justify-content-between align-items-center mb-4">
        <h2 class="mb-0">Gestión de Productos</h2>
        <div class="d-flex gap-2">
            <a href="/webapp-reserva-hotel/configuraciones.jsp" class="btn btn-outline-secondary">
                <i class="bi bi-caret-left"></i> Volver
            </a>
            <button class="btn btn-primary mr-5" @click="openCreateModal()">Nuevo Producto</button>
        </div>
    </div>
    <div class="row g-2 align-items-center">
        <div class="col-md-6">
            <div class="input-group">
                <span class="input-group-text"><i class="bi bi-search"></i></span>
                <input v-model="state.buscar" @input="onBuscarInput" type="text" class="form-control"
                       placeholder="Buscar por descripción...">
                <button v-if="state.buscar" class="btn btn-outline-secondary" @click="limpiarBusqueda" title="Limpiar">
                    <i class="bi bi-x-lg"></i>
                </button>
            </div>
        </div>
        <div class="col-md-6 text-md-end">
            <span class="badge bg-secondary fs-6">{{ state.productos.length }} registro(s)</span>
        </div>
    </div>
</header>

<main class="flex-fill">
    <table class="table table-hover table-bordered align-middle">
        <thead class="table-light">
            <tr>
                <th>#</th>
                <th>Descripción</th>
                <th>Precio (S/)</th>
                <th>Stock</th>
                <th>Estado</th>
                <th>Acciones</th>
            </tr>
        </thead>
        <tbody>
            <tr v-if="state.productos.length === 0">
                <td colspan="6" class="text-center text-muted">No hay productos registrados.</td>
            </tr>
            <tr v-for="(producto, index) in state.productos" :key="producto.idProducto">
                <td>{{ index + 1 }}</td>
                <td>{{ producto.descripcion }}</td>
                <td>{{ producto.precio }}</td>
                <td>{{ producto.cantidadStock }}</td>
                <td>
                    <span class="badge" :class="producto.estado === 'activo' ? 'bg-success' : 'bg-secondary'">
                        {{ producto.estado }}
                    </span>
                </td>
                <td>
                    <button class="btn btn-sm btn-primary me-2" title="Editar" @click="openEditModal(producto)">
                        <i class="bi bi-pencil-square"></i>
                    </button>
                    <button class="btn btn-sm btn-danger" title="Eliminar" @click="eliminarProducto(producto.idProducto)">
                        <i class="bi bi-trash"></i>
                    </button>
                </td>
            </tr>
        </tbody>
    </table>

    <!-- Modal -->
    <div class="modal fade" id="productoModal" tabindex="-1" aria-labelledby="modalLabel" aria-hidden="true">
        <div class="modal-dialog modal-lg">
            <div class="modal-content">
                <form @submit.prevent="guardarProducto">

                    <div class="modal-header">
                        <h5 class="modal-title" id="modalLabel">{{ state.isEditing ? 'Editar Producto' : 'Nuevo Producto' }}</h5>
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
                            <div class="col-md-12 mb-3">
                                <label for="descripcion" class="form-label">Descripción</label>
                                <input v-model="state.productoInForm.descripcion" type="text" class="form-control" id="descripcion" required>
                            </div>
                        </div>
                        <div class="row">
                            <div class="col-md-6 mb-3">
                                <label for="precio" class="form-label">Precio (S/)</label>
                                <input v-model="state.productoInForm.precio" type="number" step="0.01" class="form-control" id="precio" required>
                            </div>
                            <div class="col-md-6 mb-3">
                                <label for="cantidadStock" class="form-label">Cantidad en stock</label>
                                <input v-model="state.productoInForm.cantidadStock" type="number" class="form-control" id="cantidadStock" required>
                            </div>
                        </div>
                        <div class="row" v-if="state.isEditing">
                            <div class="col-md-6 mb-3">
                                <label for="estado" class="form-label">Estado</label>
                                <select v-model="state.productoInForm.estado" class="form-select" id="estado">
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
                productos: [],
                productoInForm: {estado: 'activo'},
                isEditing: false,
                buscar: '',
                messageError: null,
                messageSuccess: null,
            });

            const productoModal = ref(null);
            let buscarTimer = null;

            const onBuscarInput = () => {
                clearTimeout(buscarTimer);
                buscarTimer = setTimeout(listarProductos, 350);
            };

            const limpiarBusqueda = () => {
                state.buscar = '';
                listarProductos();
            };

            const listarProductos = async () => {
                try {
                    const url = '/webapp-reserva-hotel/ProductoServlet?action=listar&buscar=' + encodeURIComponent(state.buscar);
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
                        state.productos = data.result;
                    } else {
                        state.productos = [];
                    }
                } catch (error) {
                    console.error("ERROR en listarProductos:", error);
                    state.messageError = 'Error de conexión: ' + error.message;
                }
            };

            const openCreateModal = () => {
                state.isEditing = false;
                state.productoInForm = {estado: 'activo'};
                state.messageError = null;
                state.messageSuccess = null;
                productoModal.value.show();
            };

            const openEditModal = (producto) => {
                state.isEditing = true;
                state.productoInForm = {...producto};
                state.messageError = null;
                state.messageSuccess = null;
                productoModal.value.show();
            };

            const guardarProducto = async () => {
                const action = state.isEditing ? 'actualizar' : 'crear';
                const formData = new FormData();
                formData.append('action', action);

                for (const key in state.productoInForm) {
                    formData.append(key, state.productoInForm[key]);
                }

                try {
                    const response = await fetch('/webapp-reserva-hotel/ProductoServlet', {
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
                        listarProductos();
                        if (!state.isEditing) {
                            productoModal.value.hide();
                        }
                    } else {
                        throw new Error(data.message || "Error desconocido en el servidor");
                    }
                } catch (error) {
                    state.messageError = 'Error al guardar: ' + error.message;
                }
            };

            const eliminarProducto = async (idProducto) => {
                if (!confirm('¿Deseas eliminar este producto?'))
                    return;

                const formData = new FormData();
                formData.append('action', 'eliminar');
                formData.append('idProducto', idProducto);

                try {
                    const response = await fetch('/webapp-reserva-hotel/ProductoServlet', {
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
                        listarProductos();
                    } else {
                        throw new Error(data.message || "Error al eliminar");
                    }
                } catch (error) {
                    alert(error.message);
                }
            };

            onMounted(async () => {
                productoModal.value = new bootstrap.Modal(document.getElementById('productoModal'));
                await listarProductos();
            });

            return {
                state,
                onBuscarInput,
                limpiarBusqueda,
                openCreateModal,
                openEditModal,
                guardarProducto,
                eliminarProducto
            };
        }
    }).mount('#app');
</script>

<%@include file="includes/footer.jsp" %>
