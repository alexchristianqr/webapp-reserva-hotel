package servlets;

import controllers.ProductoController;
import core.services.ResponseService;
import core.servlets.BaseServlet;
import java.io.IOException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import models.Producto;

@WebServlet(name = "ProductoServlet", urlPatterns = {"/ProductoServlet"})
@MultipartConfig
public class ProductoServlet extends BaseServlet {

    private final ProductoController productoController = new ProductoController();

    @Override
    public void processRequest(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String action = request.getParameter("action");
        if (action == null) {
            action = "listar";
        }

        ResponseService<?> responseService;

        switch (action) {
            case "listar" ->
                responseService = listarProductos(request);
            case "crear" ->
                responseService = crearProducto(request);
            case "actualizar" ->
                responseService = actualizarProducto(request);
            case "eliminar" ->
                responseService = eliminarProducto(request);
            default ->
                responseService = defaultError(action);
        }

        sendJsonResponse(response, responseService);
    }

    private ResponseService<?> listarProductos(HttpServletRequest request) {
        String buscar = request.getParameter("buscar") != null ? request.getParameter("buscar") : "";
        return productoController.listarProductos(buscar);
    }

    private ResponseService<?> crearProducto(HttpServletRequest request) {
        Producto producto = new Producto();
        producto.setDescripcion(request.getParameter("descripcion"));
        producto.setPrecio(parseDoubleSafe(request.getParameter("precio")));
        producto.setCantidadStock(parseIntSafe(request.getParameter("cantidadStock")));
        producto.setEstado("activo"); // Valor por defecto
        return productoController.crearProducto(producto);
    }

    private ResponseService<?> actualizarProducto(HttpServletRequest request) {
        Producto producto = new Producto();
        producto.setIdProducto(parseIntSafe(request.getParameter("idProducto")));
        producto.setDescripcion(request.getParameter("descripcion"));
        producto.setPrecio(parseDoubleSafe(request.getParameter("precio")));
        producto.setCantidadStock(parseIntSafe(request.getParameter("cantidadStock")));
        producto.setEstado(request.getParameter("estado"));
        return productoController.actualizarProducto(producto);
    }

    private ResponseService<?> eliminarProducto(HttpServletRequest request) {
        Producto producto = new Producto();
        producto.setIdProducto(parseIntSafe(request.getParameter("idProducto")));
        return productoController.eliminarProducto(producto);
    }
}
