package controllers;

import core.services.ResponseService;
import java.util.List;
import java.util.Map;
import models.Habitacion;
import services.HabitacionService;

public class HabitacionController extends BaseController<Habitacion, HabitacionService> {

    public HabitacionController() {
        lista.clear();
        service = new HabitacionService();
    }

    public ResponseService<List<Habitacion>> listarHabitaciones(String buscar) {
        ResponseService<List<Habitacion>> response = new ResponseService<>();
        List<Habitacion> habitaciones = service.listarHabitaciones(buscar);

        if (habitaciones.isEmpty()) {
            response.setSuccess(false);
            response.setMessage("No hay nada que listar");
        } else {
            response.setSuccess(true);
            response.setMessage("Procesado correctamente");
            response.setResult(habitaciones);
        }

        return response;
    }

    public ResponseService<List<Map<String, Object>>> listarTiposHabitacion() {
        ResponseService<List<Map<String, Object>>> response = new ResponseService<>();
        List<Map<String, Object>> tipos = service.listarTiposHabitacion();

        response.setSuccess(true);
        response.setMessage("Procesado correctamente");
        response.setResult(tipos);

        return response;
    }

    public ResponseService<Boolean> crearHabitacion(Habitacion habitacion) {
        ResponseService<Boolean> response = new ResponseService<>();
        Boolean result = service.crearHabitacion(habitacion);

        if (!result) {
            response.setSuccess(false);
            response.setMessage("Error al guardar");
        } else {
            response.setSuccess(true);
            response.setMessage("Guardado correctamente");
            response.setResult(result);
        }

        return response;
    }

    public Habitacion encontrarHabitacion(int idHabitacion) {
        for (Habitacion oHabitacion : lista) {
            if (oHabitacion.getIdHabitacion() == idHabitacion) {
                return oHabitacion;
            }
        }
        return null;
    }

    public ResponseService<Boolean> actualizarHabitacion(Habitacion habitacion) {
        ResponseService<Boolean> response = new ResponseService<>();
        Boolean result = service.actualizarHabitacion(habitacion);

        if (!result) {
            response.setSuccess(false);
            response.setMessage("Error al actualizar");
        } else {
            response.setSuccess(true);
            response.setMessage("Actualizado correctamente");
            response.setResult(result);
        }

        return response;
    }

    public ResponseService<Boolean> eliminarHabitacion(Habitacion habitacion) {
        ResponseService<Boolean> response = new ResponseService<>();
        Boolean result = service.eliminarHabitacion(habitacion);

        if (!result) {
            response.setSuccess(false);
            response.setMessage("Error al eliminar");
        } else {
            response.setSuccess(true);
            response.setMessage("Eliminado correctamente");
            response.setResult(result);
        }

        return response;
    }
}
