<%@page contentType="text/html" pageEncoding="UTF-8"%>

<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <title>JSP Page</title>
    </head>
    <body>
        <div id="app">
            <form @submit.prevent="login">
                <label for="username">Usuario:</label><br>
                <input type="text" id="username" v-model="username" required><br>
                <label for="password">Contraseña:</label><br>
                <input type="password" id="password" v-model="password" required><br><br>
                <button type="submit">Iniciar Sesión</button>
            </form>

            <p v-if="message">{{ message }}</p>

            <table v-if="users.length > 0" border="1">
                <thead>
                    <tr>
                        <th>Nombre</th>
                        <th>Email</th>
                    </tr>
                </thead>
                <tbody>
                    <tr v-for="user in users" :key="user.username">
                        <td>{{ user.username }}</td>
                        <td>{{ user.password }}</td>
                    </tr>
                </tbody>
            </table>

            <p v-else>No hay usuarios para mostrar.</p>
        </div>

        <script src="https://unpkg.com/vue@3/dist/vue.global.js"></script>
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
                const data = await response.json();

                if (data.length > 0) {
                    users.value = data;
                    message.value = '¡Bienvenido!';
                } else {
                    users.value = [];
                    message.value = 'Credenciales incorrectas.';
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
    </body>
</html>
