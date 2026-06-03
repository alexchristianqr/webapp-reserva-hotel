# Convenciones de Código

Reglas de estilo y patrones a seguir. Replican lo que ya existe en el repo; cualquier
agente debe imitarlas para mantener coherencia.

## Backend — Servlets

```java
@WebServlet(name = "XxxServlet", urlPatterns = {"/XxxServlet"})
@MultipartConfig
public class XxxServlet extends BaseServlet {

    private final XxxController xxxController = new XxxController();

    @Override
    public void processRequest(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String action = request.getParameter("action");
        if (action == null) action = "listar";          // o "login" en autenticación

        ResponseService<?> responseService;
        switch (action) {
            case "listar"     -> responseService = listarXxx(request);
            case "crear"      -> responseService = crearXxx(request);
            case "actualizar" -> responseService = actualizarXxx(request);
            default           -> responseService = defaultError(action);
        }

        String json = new Gson().toJson(responseService);
        response.getWriter().write(json);
    }
    // ... métodos privados que construyen el model desde request.getParameter(...)
}
```

- Anota con `@WebServlet` y `@MultipartConfig` (los formularios envían `FormData`).
- Convierte números con los helpers `parseIntSafe` / `parseDoubleSafe` de `BaseServlet`.
- Nunca pongas SQL ni reglas de negocio aquí.

## Backend — Controllers

```java
public class XxxController extends BaseController<Xxx, XxxService> {
    public XxxController() {
        lista.clear();
        service = new XxxService();
    }
    public ResponseService<List<Xxx>> listarXxx(String buscar) {
        ResponseService<List<Xxx>> response = new ResponseService<>();
        List<Xxx> items = service.listarXxx();
        if (items.isEmpty()) {
            response.setSuccess(false);
            response.setMessage("No hay nada que listar");
        } else {
            response.setSuccess(true);
            response.setMessage("Procesado correctamente");
            response.setResult(items);
        }
        return response;
    }
}
```

- Siempre devuelve `ResponseService<T>` con `success` + `message`.
- Mensajes en español: "Guardado correctamente", "Error al actualizar", etc.

## Backend — Services

```java
public class XxxService extends BaseService {
    public XxxService() { db = new MysqlDBService(); }

    public List<Xxx> listarXxx() {
        List<Xxx> items = new ArrayList<>();
        querySQL_1 = "SELECT ... FROM xxx WHERE ...";
        Object[] parametrosSQL_1 = { /* params */ };
        ResultSet rs = db.queryConsultar(querySQL_1, parametrosSQL_1);
        try {
            while (rs.next()) { /* map rs → Xxx */ items.add(item); }
            return items;
        } catch (SQLException ex) {
            throw new RuntimeException(ex);
        } finally {
            db.cerrarConsulta();
        }
    }
}
```

- SQL en campos `querySQL_1..4`; parámetros en `Object[] parametrosSQL_N`.
- **Siempre** `PreparedStatement` vía `db.query*` — nunca concatenar input.
- Cierra con `db.cerrarConsulta()` en `finally` tras consultas.
- INSERT/UPDATE devuelven `Boolean`/`int`; `queryInsertar` devuelve el id generado.

## Backend — Models

- POJOs simples con getters/setters.
- `Cliente`/`Empleado` extienden `Persona`. Reutiliza `Persona` para datos personales.
- Fechas frecuentemente como `String`.

## Frontend — JSP + Vue

```jsp
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@include file="./includes/header.jsp" %>
<!-- markup con Bootstrap + directivas Vue (v-for, v-model, @click) -->
<script>
    const { createApp, reactive, onMounted, ref } = Vue;
    const redirectLogin = '/webapp-reserva-hotel/login.jsp';
    createApp({
        setup() {
            const state = reactive({ items: [], itemInForm: {}, isEditing: false,
                                     messageError: null, messageSuccess: null });
            onMounted(() => fetchItems());
            const fetchItems = async () => {
                const r = await fetch('/webapp-reserva-hotel/XxxServlet?action=listar');
                if (!r.ok) { if (r.status === 401) { window.location.href = redirectLogin; return; } throw new Error('...'); }
                const data = await r.json();
                if (data.success) state.items = data.result; else throw new Error(data.message);
            };
            // saveItem usa FormData con action incluido y method POST
            return { state, /* handlers */ };
        }
    }).mount('#app');
</script>
<%@include file="./includes/footer.jsp" %>
```

- Build global de Vue 3 (sin bundler). Bootstrap y Vue vienen por CDN en `header.jsp`.
- Una página `.jsp` por entidad, con tabla + modal de alta/edición.
- Maneja siempre `response.status === 401` redirigiendo a `login.jsp`.
- Usa rutas absolutas con el context path `/webapp-reserva-hotel/...`.

## Generales

- **Idioma**: dominio en español (clases, métodos, acciones, mensajes).
- **Codificación**: UTF-8 (configurado en `pom.xml`). Los `.jsp` declaran `pageEncoding="UTF-8"`.
- **Java 21**: se usan `switch` con flechas (`->`) y `instanceof` con patrón.
- **Rutas de archivos**: el código fuente va en `src/java/...`, **no** `src/main/java`.
- **Commits**: mensajes concisos (el historial usa frases cortas en español/inglés mixto).
