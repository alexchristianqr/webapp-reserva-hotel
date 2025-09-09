<%@include file="../includes/header.jsp" %>
<header>
    <div class="row">
        <div class="col-6 offset-3">
            <h1>Login</h1>
        </div>
    </div>
</header>

<main>
    <div class="py-3">
        <div class="row">
            <div class="col-6 offset-3">
                <form @submit.prevent="login">
                    <div class="mb-3">
                        <label for="username" class="form-label">Usuario</label>
                        <input 
                            type="text" 
                            id="username" 
                            v-model="username" 
                            required 
                            class="form-control"
                            >
                    </div>
                    <div class="mb-3">
                        <label for="password" class="form-label">Contraseña</label>
                        <input 
                            type="password" 
                            id="password" 
                            v-model="password" 
                            required 
                            class="form-control"
                            >
                    </div>
                    <div class="d-grid gap-3">
                        <button type="submit" class="btn btn-primary">Iniciar Sesión</button>
                    </div>
                </form>
            </div>
        </div>
    </div>
</main>

<script>
    const {createApp, ref} = Vue;

    createApp({
        setup() {
            const username = ref('');
            const password = ref('');
            const message = ref('');
            const users = ref([]);

            const login = async () => {
                // Crea un objeto FormData para enviar los datos del formulario
                const formData = new FormData();
                formData.append('username', username.value);
                formData.append('password', password.value);

                // Petición al servlet usando Fetch
                try {
                    const response = await fetch('LoginServlet', {
                        method: 'POST',
                        body: formData
                    });
                    if (!response.ok) {
                        throw new Error('Network response was not ok');
                    }

                    // Espera a que la respuesta se convierta a JSON
                    const {success, result, message} = await response.json();

                    if (success) {
                        users.value = result;
                        message.value = '¡Bienvenido!';
                        alert(message);
                    } else {
                        alert("Error de usuario o contraseña");
//                        users.value = [];
//                        message.value = 'Credenciales incorrectas';
                    }
                } catch (error) {
                    console.error('Error:', error);
                    message.value = 'Error de conexión.';
                }
            };

            return {
                username,
                password,
                message,
                users,
                login
            };
        }
    }).mount('#app');
</script>
<%@include file="../includes/footer.jsp" %>
