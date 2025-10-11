package controllers;

import core.services.ResponseService;
import java.util.List;
import models.Habitacion;
import services.HabitacionService;

public class HabitacionController extends BaseController<Habitacion, HabitacionService> {

    public HabitacionController() {
        lista.clear();
        service = new HabitacionService();
    }

    public ResponseService<List<Habitacion>> listarHabitaciones(String buscar) {
        ResponseService<List<Habitacion>> response = new ResponseService<>();
        List<Habitacion> habitaciones = service.listarHabitaciones();

        if (habitaciones.isEmpty()) {
            response.setSuccess(false);
            response.setMessage("No hay nada que listar");
        } else {
            response.setSuccess(true);
            response.setMessage("Listado con éxito");
            response.setResult(habitaciones);
        }

        return response;
    }

    public void crearHabitacion(Habitacion habitacion) {
        service.crearHabitacion(habitacion);
    }

    public Habitacion encontrarHabitacion(int idHabitacion) {
        for (Habitacion oHabitacion : lista) {
            if (oHabitacion.getIdHabitacion() == idHabitacion) {
                return oHabitacion;
            }
        }
        return null;
    }

    public void actualizarHabitacion(Habitacion habitacion) {
        service.actualizarHabitacion(habitacion);
    }

    public void eliminarHabitacion(int idHabitacion) {
        for (Habitacion oHabitacion : lista) {
            if (oHabitacion.getIdHabitacion() == idHabitacion) {
                lista.remove(oHabitacion);
                break;
            }
        }
    }
}
