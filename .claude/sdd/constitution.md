# Constitución del Proyecto

> Principios y reglas **inviolables**. Todo plan, tarea o código debe cumplirlas.
> Si una petición las contradice, el agente debe detenerse y señalarlo.

## Artículo I — Coherencia arquitectónica

1. Toda petición HTTP fluye en capas, sin saltarse ninguna:
   **Servlet → Controller → Service → MysqlDBService → MySQL**.
2. Un **Servlet** nunca contiene SQL ni lógica de negocio: solo parsea parámetros,
   despacha por `action` y serializa la respuesta.
3. Un **Controller** nunca accede a la base de datos directamente: delega en su Service.
4. Un **Service** es el único lugar donde vive el SQL.
5. Las vistas (`.jsp`) solo se comunican con el backend vía `fetch` a un Servlet.

## Artículo II — Contrato de respuesta

1. Toda respuesta del backend al frontend es un `ResponseService<T>` serializado a JSON.
2. `success` (boolean) y `message` (String) son **obligatorios** en cada respuesta.
3. Los errores de sesión devuelven HTTP `401` con `redirectUrl` hacia `login.jsp`.
4. Una acción desconocida se responde con `defaultError(action)`.

## Artículo III — Seguridad de datos

1. **Todo** acceso a BD usa `PreparedStatement` con parámetros `Object[]`.
   Está **prohibido** concatenar entrada de usuario dentro de una cadena SQL.
2. Las rutas protegidas exigen sesión válida (`BaseServlet.verificarSesion`).
3. Los recursos JDBC se cierran tras su uso (`db.cerrarConsulta()`).

## Artículo IV — Idioma y nomenclatura

1. El dominio se nombra en **español**: `Cliente`, `Habitacion`, `Reserva`,
   `listar`, `crear`, `actualizar`, `eliminar`.
2. Se mantiene el estilo de nombres existente; no se introducen mezclas de idiomas
   sin justificación.

## Artículo V — Simplicidad y mínimo cambio

1. Reutiliza las clases base (`BaseServlet`, `BaseController`, `BaseService`) y los
   patrones existentes antes de crear nuevos.
2. No se añaden dependencias, frameworks ni capas nuevas sin que la especificación
   lo justifique explícitamente.
3. Se prefiere replicar el patrón de una entidad ya existente (p. ej. `Cliente`)
   sobre inventar uno nuevo.

## Artículo VI — La especificación manda

1. No se escribe código sin una especificación (`spec.md`) y un plan (`plan.md`)
   para cambios no triviales.
2. Si la implementación revela que la spec estaba equivocada, **se actualiza la spec**
   y se deja constancia, en lugar de divergir en silencio.
3. Cualquier cambio que altere arquitectura o modelo de dominio obliga a actualizar
   el archivo correspondiente en `.claude/sdd/`.

## Artículo VII — Verificación

1. Todo cambio debe, como mínimo, **compilar** (`mvn -q clean package`).
2. Si existen o se añaden tests, deben pasar (`mvn test`).
3. Los cambios de UI se verifican arrancando la app (`run.bat`) cuando sea posible.

## Enmiendas

Esta constitución puede modificarse, pero cada enmienda debe registrarse aquí con
fecha y motivo. Las enmiendas no son retroactivas sobre código ya entregado salvo
que una tarea lo indique.

| Fecha       | Enmienda                          |
|-------------|-----------------------------------|
| 2026-06-02  | Versión inicial de la constitución |
