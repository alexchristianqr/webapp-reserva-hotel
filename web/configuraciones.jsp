<%@include file="../includes/header.jsp" %>

<header class="py-3 border-bottom mb-4">
    <div class="d-flex justify-content-between align-items-center mb-4">
        <h2 class="mb-0">Panel de Configuración</h2>

        <div class="d-flex gap-2">
            <a href="/webapp-reserva-hotel/home.jsp" class="btn btn-outline-secondary">
                <i class="bi bi-caret-left"></i> Volver
            </a>
        </div>
    </div>
</header>

<main class="flex-fill">
    <p class="text-muted mb-5">
        Administra la información del sistema: habitaciones, empleados, productos, usuarios y clientes.
    </p>

    <!-- Tarjetas de configuración -->
    <div class="row g-4 pb-5">
        <!-- Habitaciones -->
        <div class="col-md-4">
            <div class="card shadow-sm h-100 text-center p-3 border-0">
                <div class="card-body">
                    <i class="bi bi-door-closed display-4 text-primary"></i>
                    <h5 class="card-title mt-3">Habitaciones</h5>
                    <p class="text-muted">Gestiona las habitaciones disponibles en el hotel.</p>
                    <a href="habitaciones.jsp" class="btn btn-primary">Administrar</a>
                </div>
            </div>
        </div>

        <!-- Empleados -->
        <div class="col-md-4">
            <div class="card shadow-sm h-100 text-center p-3 border-0">
                <div class="card-body">
                    <i class="bi bi-person-badge display-4 text-success"></i>
                    <h5 class="card-title mt-3">Empleados</h5>
                    <p class="text-muted">Administra el personal y sus roles dentro del sistema.</p>
                    <a href="empleados.jsp" class="btn btn-success">Administrar</a>
                </div>
            </div>
        </div>

<!--         Productos 
        <div class="col-md-4">
            <div class="card shadow-sm h-100 text-center p-3 border-0">
                <div class="card-body">
                    <i class="bi bi-basket display-4 text-warning"></i>
                    <h5 class="card-title mt-3">Productos</h5>
                    <p class="text-muted">Controla los productos del inventario y servicios adicionales.</p>
                    <a href="productos.jsp" class="btn btn-warning text-white">Administrar</a>
                </div>
            </div>
        </div>

         Usuarios 
        <div class="col-md-4">
            <div class="card shadow-sm h-100 text-center p-3 border-0">
                <div class="card-body">
                    <i class="bi bi-people display-4 text-secondary"></i>
                    <h5 class="card-title mt-3">Usuarios</h5>
                    <p class="text-muted">Gestiona los accesos y credenciales del sistema.</p>
                    <a href="usuarios.jsp" class="btn btn-secondary">Administrar</a>
                </div>
            </div>
        </div>-->

        <!-- Clientes -->
        <div class="col-md-4">
            <div class="card shadow-sm h-100 text-center p-3 border-0">
                <div class="card-body">
                    <i class="bi bi-person-lines-fill display-4 text-danger"></i>
                    <h5 class="card-title mt-3">Clientes</h5>
                    <p class="text-muted">Consulta y gestiona los datos de tus huéspedes.</p>
                    <a href="clientes.jsp" class="btn btn-danger">Administrar</a>
                </div>
            </div>
        </div>
    </div>

</main>

<script>
    const {createApp, reactive} = Vue;

    createApp({
        setup() {
            const state = reactive({
                user: JSON.parse(localStorage.getItem('user')) || {name: 'Invitado'}
            });
            return {state};
        }
    }).mount('#app');
</script>

<%@include file="../includes/footer.jsp" %>
