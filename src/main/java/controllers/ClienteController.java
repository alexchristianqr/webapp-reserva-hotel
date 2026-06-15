package controllers;

import core.BaseController;
import core.services.ResponseService;
import java.util.List;
import services.ClienteService;
import models.Cliente;

public class ClienteController extends BaseController<Cliente, ClienteService> {

    public ClienteController() {
        lista.clear();
        service = new ClienteService();
    }

    public ResponseService<List<Cliente>> listarClientes(String buscar) {
        ResponseService<List<Cliente>> response = new ResponseService<>();
        List<Cliente> clientes = service.listarClientes(buscar);

        if (clientes.isEmpty()) {
            response.setSuccess(false);
            response.setMessage("No hay nada que listar");
        } else {
            response.setSuccess(true);
            response.setMessage("Procesado correctamente");
            response.setResult(clientes);
        }

        return response;
    }

    public ResponseService<Boolean> crearCliente(Cliente cliente) {
        ResponseService<Boolean> response = new ResponseService<>();
        try {
            Boolean success = service.crearCliente(cliente);
            response.setSuccess(success);
            response.setMessage(success ? "Guardado correctamente" : "Error al guardar");
        } catch (RuntimeException e) {
            response.setSuccess(false);
            response.setMessage(e.getMessage());
        }
        return response;
    }

    public ResponseService<Boolean> actualizarCliente(Cliente cliente) {
        ResponseService<Boolean> response = new ResponseService<>();
        try {
            Boolean success = service.actualizarCliente(cliente);
            response.setSuccess(success);
            response.setMessage(success ? "Actualizado correctamente" : "Error al actualizar");
        } catch (RuntimeException e) {
            response.setSuccess(false);
            response.setMessage(e.getMessage());
        }
        return response;
    }

    public ResponseService<Boolean> eliminarCliente(Cliente cliente) {
        ResponseService<Boolean> response = new ResponseService<>();
        Boolean success = service.eliminarCliente(cliente);

        if (!success) {
            response.setSuccess(false);
            response.setMessage("Error al eliminar");
        } else {
            response.setSuccess(true);
            response.setMessage("Eliminado correctamente");
        }

        return response;
    }
}
