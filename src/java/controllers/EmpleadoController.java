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
            response.setMessage("Listado con éxito");
            response.setResult(empleados);
        }

        return response;
    }

    public void crearEmpleado(Empleado empleado) {
        service.crearEmpleado(empleado);
    }

    public void actualizarEmpleado(Empleado empleado) {
        service.actualizarEmpleado(empleado);
    }
}
