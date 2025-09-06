package controllers;

import javax.swing.table.DefaultTableModel;
import models.Empleado;
import services.EmpleadoService;

public class EmpleadoController extends BaseController<Empleado, EmpleadoService> {

    public EmpleadoController() {
        lista.clear();
        service = new EmpleadoService();
    }

    public DefaultTableModel listarEmpleados(String buscar) {
        DefaultTableModel modelo;
        String[] columnNames = {"Código", "Nombres", "Apellidos", "Tipo Doc.", "Nro Doc.", "Sueldo", "Perfil", "Edad", "Sexo", "Telefono", "Estado", "Fecha creado", "Fecha actualizado"};
        Object[] data = new Object[columnNames.length];
        modelo = new DefaultTableModel(null, columnNames);
        modelo = service.listarEmpleados(modelo, data);
        return modelo;
    }

    public void crearEmpleado(Empleado empleado) {
        service.crearEmpleado(empleado);
    }

    public void actualizarEmpleado(Empleado empleado) {
        service.actualizarEmpleado(empleado);
    }
}
