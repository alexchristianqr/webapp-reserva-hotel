package services;

import core.services.MysqlDBService;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import models.Producto;

public class ProductoService extends BaseService {

    public ProductoService() {
        db = new MysqlDBService();
    }

    public List<Producto> listarProductos() {

        List<Producto> productos = new ArrayList<>();

        querySQL_1 = "SELECT id, descripcion, precio, cantidad_stock, estado, fecha_creado, fecha_actualizado FROM productos";
        Object[] parametrosSQL_1 = {};
        ResultSet rs = db.queryConsultar(querySQL_1, parametrosSQL_1);

        try {
            while (rs.next()) {
                Producto producto = new Producto();
                producto.setIdProducto(rs.getInt("id"));
                producto.setDescripcion(rs.getString("descripcion"));
                producto.setPrecio(rs.getFloat("precio")); // BigDecimal para precios
                producto.setCantidadStock(rs.getInt("cantidad_stock"));
                producto.setEstado(rs.getString("estado"));
                producto.setFechaCreado(rs.getString("fecha_creado"));
                producto.setFechaActualizado(rs.getString("fecha_actualizado"));
                productos.add(producto);
            }

            return productos;
        } catch (SQLException ex) {
            throw new RuntimeException(ex);
        } finally {
            db.cerrarConsulta();
        }
    }

    // Método para agregar un nuevo producto
    public Boolean crearProducto(Producto producto) {
        querySQL_1 = "INSERT INTO productos (descripcion, precio, cantidad_stock) VALUES (?, ?, ?)";
        Object[] parametros = {
            producto.getDescripcion(),
            producto.getPrecio(),
            producto.getCantidadStock()
        };

        db.queryInsertar(querySQL_1, parametros);
        db.cerrarConsulta();
        return true;
    }

    // Método para actualizar un producto existente
    public Boolean actualizarProducto(Producto producto) {
        querySQL_1 = "UPDATE productos SET descripcion = ?, precio = ?, cantidad_stock = ?, fecha_actualizado = CURRENT_TIMESTAMP WHERE id = ?";
        Object[] parametros = {
            producto.getDescripcion(),
            producto.getPrecio(),
            producto.getCantidadStock(),
            producto.getIdProducto(),};

        db.queryActualizar(querySQL_1, parametros);
        db.cerrarConsulta();
        return true;
    }

    // Método para eliminar un producto por su código
    public Boolean eliminarProducto(Producto producto) {
        querySQL_1 = "DELETE FROM productos WHERE id = ?";
        Object[] parametros = {producto.getIdProducto()};

        db.queryEliminar(querySQL_1, parametros);
        db.cerrarConsulta();
        return true;
    }
}
