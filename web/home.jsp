<%@include file="../includes/header.jsp" %>

<header>
    <div class="row">
        <div class="col-6">
            <h1>Home</h1>
        </div>
    </div>
</header>

<main>
    <div>
        <!-- Encabezado -->
        <div class="d-flex justify-content-between align-items-center mb-4">
            <h2>Bienvenido, {{ state.user?.nombres || 'Usuario' }}</h2>
            <button class="btn btn-outline-danger" @click="logout">
                <i class="bi bi-box-arrow-right"></i> Cerrar sesión
            </button>
        </div>

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
                @click="welcomeMessage = null" 
                aria-label="Close">
            </button>
        </div>

        <!-- Acciones principales -->
        <div class="row g-4 mb-5">
            <div class="col-md-4">
                <div class="card shadow-sm h-100 text-center p-3">
                    <div class="card-body">
                        <i class="bi bi-calendar-plus display-4 text-primary"></i>
                        <h5 class="card-title mt-3">Nueva reserva</h5>
                        <p class="card-text text-muted">Crea una nueva reserva para tus huéspedes.</p>
                        <button class="btn btn-primary" @click="goToNewReservation">Reservar</button>
                    </div>
                </div>
            </div>

            <div class="col-md-4">
                <div class="card shadow-sm h-100 text-center p-3">
                    <div class="card-body">
                        <i class="bi bi-journal-check display-4 text-success"></i>
                        <h5 class="card-title mt-3">Mis reservas</h5>
                        <p class="card-text text-muted">Consulta tus reservas activas o pasadas.</p>
                        <button class="btn btn-success" @click="goToReservations">Ver reservas</button>
                    </div>
                </div>
            </div>

            <div class="col-md-4">
                <div class="card shadow-sm h-100 text-center p-3">
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
        <div>
            <h4 class="mb-3">Últimas reservas</h4>
            <div v-if="state.reservations.length === 0" class="text-muted">
                No hay reservas registradas.
            </div>
            <table v-else class="table table-striped align-middle shadow-sm">
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
                        <td>{{ r.client }}</td>
                        <td>{{ r.room }}</td>
                        <td>{{ r.checkIn }}</td>
                        <td>{{ r.checkOut }}</td>
                        <td>
                            <span 
                                class="badge" 
                                :class="r.status === 'confirmada' ? 'bg-success' : 'bg-secondary'"
                                >
                                {{ r.status }}
                            </span>
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>
    </div>
</main>

<script>
    const {createApp, ref, onMounted, reactive} = Vue;
    createApp({
        setup() {
//            const user = ref(JSON.parse(localStorage.getItem('user')) || {name: 'Invitado'});

            // Un solo objeto reactivo para todo el estado
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

                try {
                    const response = await fetch('autenticacion/LogoutServlet', {
                        method: 'POST',
                        body: formData
                    });

                    if (!response.ok) {
                        throw new Error('Error de red');
                    }

                    const {success, result, message} = await response.json();
                    console.log({success, result, message});

                    if (success) {
//                        state.user = result;
//                        state.message = '¡Bienvenido!';
//                        localStorage.removeItem('user');
                        window.location.href = '/webapp-reserva-hotel/login.jsp';
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

//                const formData = new FormData();

                try {
                    const response = await fetch('HomeServlet', {
                        method: 'GET',
//                        body: formData
                    });

                    if (!response.ok) {
                        throw new Error('Error de red');
                    }

                    const {success, result, message} = await response.json();
                    console.log({success, result, message});

                    if (success) {
//                        console.log()
                        state.user = result;
//                        state.message = '¡Bienvenido!';
//                        localStorage.removeItem('user');
//                        window.location.href = '/webapp-reserva-hotel/login.jsp';
                    } else {
                        state.messageError = message || 'Usuario o contraseña incorrectos';
                    }
                } catch (error) {
                    console.error(error);
                    state.messageError = error.message;
                }
            };
            const goToNewReservation = () => {
                window.location.href = 'newReservation.jsp';
            };
            const goToReservations = () => {
                window.location.href = 'reservations.jsp';
            };
            const goToSettings = () => {
                window.location.href = 'settings.jsp';
            };
            onMounted(async () => {
                // Simulación de datos: podrías reemplazar por fetch('ReservationServlet')
                state.reservations = [
                    {id: 1, client: 'Carlos Pérez', room: 'Suite 301', checkIn: '2025-10-08', checkOut: '2025-10-12', status: 'confirmada'},
                    {id: 2, client: 'Lucía Gómez', room: 'Habitación Deluxe', checkIn: '2025-10-10', checkOut: '2025-10-15', status: 'pendiente'}
                ];
                me();
            });
            return {
                state,
                me,
                logout,
                goToNewReservation,
                goToReservations,
                goToSettings
            };
        }
    }).mount('#app');
</script>

<%@include file="../includes/footer.jsp" %>

