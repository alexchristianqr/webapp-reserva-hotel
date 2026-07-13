<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@include file="includes/header.jsp" %>

<header class="py-4 mb-4 text-center">
    <i class="bi bi-building text-primary" style="font-size: 5rem;"></i>
    <div class="d-flex justify-content-center align-items-center gap-2">
        <h2 class="mb-0">Hotel Reservas</h2>
    </div>
</header>

<main class="flex-fill">
    <div class="py-3">
        <div class="row">
            <div class="col-6 offset-3">

                <!-- ALERTA DE ERROR CONTROLADA POR VUE -->
                <div 
                    v-if="state.messageError" 
                    class="alert alert-danger alert-dismissible fade show" 
                    role="alert"
                    >
                    <strong>Error:</strong> {{ state.messageError }}
                    <button 
                        type="button" 
                        class="btn-close" 
                        @click="state.messageError = null"
                        aria-label="Close">
                    </button>
                </div>
                <!-- . -->

                <!-- Formulario -->
                <form @submit.prevent="login">
                    <div class="mb-3">
                        <label for="username" class="form-label">Usuario</label>
                        <input 
                            v-model="state.username"
                            type="text"
                            id="username"
                            class="form-control"
                            required
                            />
                    </div>

                    <div class="mb-3">
                        <label for="password" class="form-label">Contraseña</label>
                        <div class="input-group">
                            <input
                                v-model="state.password"
                                :type="state.showPassword ? 'text' : 'password'"
                                id="password"
                                class="form-control"
                                required
                                />
                            <button
                                type="button"
                                class="btn btn-outline-secondary"
                                @click="state.showPassword = !state.showPassword"
                                :title="state.showPassword ? 'Ocultar contraseña' : 'Mostrar contraseña'">
                                <i class="bi" :class="state.showPassword ? 'bi-eye-slash' : 'bi-eye'"></i>
                            </button>
                        </div>
                        <!-- Ayuda para validar exactamente lo que se envía (útil para detectar espacios) -->
                        <small class="text-muted d-block mt-1" v-if="state.showPassword">
                            Se enviará → usuario: <code>{{ state.username }}</code>
                            · contraseña: <code>{{ state.password }}</code>
                            ({{ state.password.length }} caracteres)
                        </small>
                    </div>

                    <div class="d-grid">
                        <button class="btn btn-primary" type="submit">Iniciar sesion</button>
                    </div>
                </form>
                <!-- . -->
            </div>
        </div>
    </div>
</main>

<script>
    const {createApp, reactive} = Vue;

    createApp({
        setup() {
            const state = reactive({
                username: '',
                password: '',
                showPassword: false,
                user: {},
                message: '',
                messageError: null
            });

            const login = async () => {
                state.messageError = null;

                const formData = new FormData();
                formData.append('action', 'login');
                formData.append('username', state.username);
                formData.append('password', state.password);

                try {
                    const response = await fetch('AutenticacionServlet', {
                        method: 'POST',
                        body: formData
                    });

                    if (!response.ok) {
                        throw new Error('Error de red');
                    }

                    const {success, result, message, code, redirectUrl} = await response.json();
                    console.log({success, result, message});

                    if (success) {
                        state.user = result;
                        state.message = '�Bienvenido!';
                        window.location.href = 'home.jsp';
                    } else {
                        state.messageError = message || 'Usuario o contrase�a incorrectos';
                    }
                } catch (error) {
                    console.error(error);
                    state.messageError = error.message;
                }
            };

            return {
                state,
                login
            };
        }
    }).mount('#app');
</script>

<%@include file="includes/footer.jsp" %>
