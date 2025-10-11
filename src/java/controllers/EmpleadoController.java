package controllers;

import core.services.ResponseService;
import java.util.List;
import models.Empleado;
import services.EmpleadoService;

public class EmpleadoController extends BaseController<Empleado, EmpleadoService> {

    public EmpleadoController() {
        lista.clear();
        service = new EmpleadoService();
    }

    public ResponseService<List<Empleado>> listarEmpleados(String buscar) {
        ResponseService<List<Empleado>> response = new ResponseService<>();
        List<Empleado> empleados = service.listarEmpleados();

        if (empleados.isEmpty()) {
            response.setSuccess(false);
            response.setMessage("No hay nada que listar");
        } else {
            response.setSuccess(true);
            response.setMessage("Procesado correctamente");
            response.setResult(empleados);
        }

        return response;
    }

    public ResponseService<Boolean> crearEmpleado(Empleado empleado) {
        ResponseService<Boolean> response = new ResponseService<>();
        Boolean success = service.crearEmpleado(empleado);

        if (!success) {
            response.setSuccess(false);
            response.setMessage("Error al guardar");
        } else {
            response.setSuccess(true);
            response.setMessage("Guardado correctamente");
        }

        return response;
    }

    public ResponseService<Boolean> actualizarEmpleado(Empleado empleado) {
        ResponseService<Boolean> response = new ResponseService<>();
        Boolean success = service.actualizarEmpleado(empleado);

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
