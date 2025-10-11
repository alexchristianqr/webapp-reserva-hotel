package controllers;

import core.services.ResponseService;
import java.util.List;
import services.ProductoService;
import models.Producto;

public class ProductoController extends BaseController<Producto, ProductoService> {

    public ProductoController() {
        lista.clear();
        service = new ProductoService();
    }

    public ResponseService<List<Producto>> listarProductos(String buscar) {
        ResponseService<List<Producto>> response = new ResponseService<>();
        List<Producto> productos = service.listarProductos();

        if (productos.isEmpty()) {
            response.setSuccess(false);
            response.setMessage("No hay nada que listar");
        } else {
            response.setSuccess(true);
            response.setMessage("Procesado correctamente");
            response.setResult(productos);
        }

        return response;
    }

    public ResponseService<Boolean> crearProducto(Producto producto) {
        ResponseService<Boolean> response = new ResponseService<>();
        Boolean success = service.crearProducto(producto);

        if (!success) {
            response.setSuccess(false);
            response.setMessage("Error al guardar");
        } else {
            response.setSuccess(true);
            response.setMessage("Guardado correctamente");
        }

        return response;
    }

    public ResponseService<Boolean> actualizarProducto(Producto producto) {
        ResponseService<Boolean> response = new ResponseService<>();
        Boolean success = service.actualizarProducto(producto);

        if (!success) {
            response.setSuccess(false);
            response.setMessage("Error al actualizar");
        } else {
            response.setSuccess(true);
            response.setMessage("Actualizado correctamente");
        }

        return response;
    }

    public ResponseService<Boolean> eliminarProducto(Producto producto) {
        ResponseService<Boolean> response = new ResponseService<>();
        Boolean success = service.eliminarProducto(producto);

        if (!success) {
            response.setSuccess(false);
            response.setMessage("Error al eliminar");
        } else {
            response.setSuccess(true);
            response.setMessage("Eliminado correctamente");
        }

        return response;
    }

    public double obtenerPrecio(String nombre) {
        for (Producto producto : lista) {
            if (nombre.equals(producto.getDescripcion())) {
                return producto.getPrecio();
            }
        }
        return 0;
    }

}
