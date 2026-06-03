package controllers;

import core.services.ResponseService;
import java.util.List;
import models.Habitacion;
import services.ReservaService;
import models.Reserva;

public class ReservaController extends BaseController<Reserva, ReservaService> {

    public ReservaController() {
        lista.clear();
        service = new ReservaService();
    }

    public ResponseService<List<Reserva>> listarReservas(String buscar) {
        ResponseService<List<Reserva>> response = new ResponseService<>();
        List<Reserva> reservas = service.listarReservas();

        if (reservas.isEmpty()) {
            response.setSuccess(false);
            response.setMessage("No hay nada que listar");
        } else {
            response.setSuccess(true);
            response.setMessage("Procesado correctamente");
            response.setResult(reservas);
        }

        return response;
    }

    // Habitaciones libres para el rango de fechas (idReservaExcluir = 0 si es reserva nueva)
    public ResponseService<List<Habitacion>> listarHabitacionesDisponibles(String fechaEntrada, String fechaSalida, int idReservaExcluir) {
        ResponseService<List<Habitacion>> response = new ResponseService<>();

        try {
            List<Habitacion> habitaciones = service.listarHabitacionesDisponibles(fechaEntrada, fechaSalida, idReservaExcluir);
            response.setSuccess(true);
            response.setMessage(habitaciones.isEmpty()
                    ? "No hay habitaciones disponibles para las fechas seleccionadas"
                    : "Procesado correctamente");
            response.setResult(habitaciones);
        } catch (IllegalArgumentException e) {
            response.setSuccess(false);
            response.setMessage(e.getMessage());
        }

        return response;
    }

    public ResponseService<Boolean> crearReserva(Reserva reserva) {
        ResponseService<Boolean> response = new ResponseService<>();

        try {
            Boolean success = service.crearReserva(reserva);
            response.setSuccess(success);
            response.setMessage(success ? "Guardado correctamente" : "Error al guardar");
        } catch (IllegalArgumentException e) {
            // validaciones de negocio: fechas inválidas, habitación ocupada, etc.
            response.setSuccess(false);
            response.setMessage(e.getMessage());
        }

        return response;
    }

    public ResponseService<Boolean> actualizarReserva(Reserva reserva) {
        ResponseService<Boolean> response = new ResponseService<>();

        try {
            Boolean success = service.actualizarReserva(reserva);
            response.setSuccess(success);
            response.setMessage(success ? "Actualizado correctamente" : "Error al actualizar");
        } catch (IllegalArgumentException e) {
            response.setSuccess(false);
            response.setMessage(e.getMessage());
        }

        return response;
    }

    public ResponseService<Boolean> cancelarReserva(int idReserva) {
        ResponseService<Boolean> response = new ResponseService<>();
        Boolean success = service.cancelarReserva(idReserva);

        if (!success) {
            response.setSuccess(false);
            response.setMessage("No se encontró la reserva a cancelar");
        } else {
            response.setSuccess(true);
            response.setMessage("Reserva cancelada correctamente");
        }

        return response;
    }

}
