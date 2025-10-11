package controllers;

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
        List<Cliente> clientes = service.listarClientes();

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
        Boolean success = service.crearCliente(cliente);

        if (!success) {
            response.setSuccess(false);
            response.setMessage("Error al guardar");
        } else {
            response.setSuccess(true);
            response.setMessage("Guardado correctamente");
        }

        return response;
    }

    public ResponseService<Boolean> actualizarCliente(Cliente cliente) {
        ResponseService<Boolean> response = new ResponseService<>();
        Boolean success = service.actualizarCliente(cliente);

        if (!success) {
            response.setSuccess(false);
            response.setMessage("Error al actualizar");
        } else {
            response.setSuccess(true);
            response.setMessage("Actualizado correctamente");
        }

        return response;
    }
}
