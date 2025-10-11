<%@include file="../includes/header.jsp" %>


<header class="py-3 border-bottom mb-4">
    <div class="d-flex justify-content-between align-items-center mb-4">
        <h2 class="mb-0">Bienvenido, {{ state.user?.nombres || 'Usuario' }}</h2>

        <div class="d-flex gap-2">
            <button class="btn btn-outline-danger" @click="logout">
                <i class="bi bi-box-arrow-right"></i> Cerrar sesión
            </button>
        </div>
    </div>
</header>

<main class="flex-fill">
    <!-- Alerta de bienvenida -->
    <div 
        v-if="state.welcomeMessage"
        class="alert alert-success alert-dismissible fade show"
        role="alert"
        >
        {{ state.welcomeMessage }}
        <button 
            type="button" 
            class="btn-close" 
            @click="state.welcomeMessage = null" 
            aria-label="Close">
        </button>
    </div>

    <!-- Acciones principales -->
    <div class="row g-4 mb-5">
        <div class="col-md-4">
            <div class="card h-100 text-center p-3">
                <div class="card-body">
                    <i class="bi bi-calendar-plus display-4 text-primary"></i>
                    <h5 class="card-title mt-3">Nueva reserva</h5>
                    <p class="card-text text-muted">Crea una nueva reserva para tus huéspedes.</p>
                    <button class="btn btn-primary" @click="goToNewReservation">Reservar</button>
                </div>
            </div>
        </div>

        <div class="col-md-4">
            <div class="card h-100 text-center p-3">
                <div class="card-body">
                    <i class="bi bi-journal-check display-4 text-success"></i>
                    <h5 class="card-title mt-3">Mis reservas</h5>
                    <p class="card-text text-muted">Consulta tus reservas activas o pasadas.</p>
                    <button class="btn btn-success" @click="goToReservations">Ver reservas</button>
                </div>
            </div>
        </div>

        <div class="col-md-4">
            <div class="card h-100 text-center p-3">
                <div class="card-body">
                    <i class="bi bi-gear display-4 text-secondary"></i>
                    <h5 class="card-title mt-3">Configuración</h5>
                    <p class="card-text text-muted">Actualiza tus datos o preferencias del sistema.</p>
                    <button class="btn btn-secondary" @click="goToSettings">Configurar</button>
                </div>
            </div>
        </div>
    </div>

    <!-- Últimas reservas -->
    <div class="py-3">
        <h4 class="mb-3">Últimas reservas</h4>
        <div v-if="state.reservations.length === 0" class="text-muted">
            No hay reservas registradas.
        </div>
        <table v-else class="table table-hover table-bordered align-middle">
            <thead class="table-light">
                <tr>
                    <th>#</th>
                    <th>Cliente</th>
                    <th>Habitación</th>
                    <th>Check-in</th>
                    <th>Check-out</th>
                    <th>Estado</th>
                </tr>
            </thead>
            <tbody>
                <tr v-for="(r, index) in state.reservations" :key="r.id">
                    <td>{{ index + 1 }}</td>
                    <td>{{ r.cliente.nombre }}</td>
                    <td>{{ r.habitacion.descripcion }}</td>
                    <td>{{ r.fechaEntrada }}</td>
                    <td>{{ r.fechaSalida }}</td>
                    <td>
                        <span 
                            class="badge" 
                            :class="r.estado === 'activo' ? 'bg-success' : 'bg-secondary'"
                            >
                            {{ r.estado }}
                        </span>
                    </td>
                </tr>
            </tbody>
        </table>
    </div>
</main>

<script>
    const {createApp, ref, onMounted, reactive} = Vue;
    const redirectLogin = '/webapp-reserva-hotel/login.jsp';

    createApp({
        setup() {
            const state = reactive({
                username: '',
                password: '',
                user: {},
                welcomeMessage: '',
                reservations: [],
                message: '',
                messageError: null,
            });

            const logout = async () => {
                state.messageError = null;

                const formData = new FormData();
                formData.append('action', 'logout');

                try {
                    const response = await fetch('AutenticacionServlet', {
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

                    const {success, result, message} = await response.json();
                    console.log({success, result, message});

                    if (success) {
                        window.location.href = redirectLogin;
                    } else {
                        state.messageError = message || 'Usuario o contraseña incorrectos';
                    }
                } catch (error) {
                    console.error(error);
                    state.messageError = error.message;
                }
            };
            const me = async () => {
                state.messageError = null;

                try {
                    const response = await fetch('HomeServlet', {
                        method: 'GET',
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
                        state.user = result;
                    } else {
                        state.messageError = message || 'Usuario o contraseña incorrectos';
                    }
                } catch (error) {
                    console.error(error);
                    state.messageError = error.message;
                }
            };
            const getReservations = async () => {
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
                        state.reservations = result;
                    } else {
                        state.messageError = message || 'Usuario o contraseña incorrectos';
                    }
                } catch (error) {
                    console.error(error);
                    state.messageError = error.message;
                }
            };
            const goToNewReservation = () => {
                window.location.href = 'reservas.jsp';
            };
            const goToReservations = () => {
                window.location.href = 'reservas.jsp';
            };
            const goToSettings = () => {
                window.location.href = 'configuraciones.jsp';
            };

            onMounted(async () => {
                me();
                getReservations();
            });

            return {
                state,
                logout,
                goToNewReservation,
                goToReservations,
                goToSettings
            };
        }
    }).mount('#app');
</script>

<%@include file="../includes/footer.jsp" %>

