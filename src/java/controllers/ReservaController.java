package controllers;

import core.services.ResponseService;
import java.util.List;
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

    public ResponseService<Boolean> crearReserva(Reserva reserva) {
        ResponseService<Boolean> response = new ResponseService<>();
        Boolean success = service.crearReserva(reserva);

        if (!success) {
            response.setSuccess(false);
            response.setMessage("Error al guardar");
        } else {
            response.setSuccess(true);
            response.setMessage("Guardado correctamente");
        }

        return response;
    }

    public ResponseService<Boolean> actualizarReserva(Reserva reserva) {
        ResponseService<Boolean> response = new ResponseService<>();
        Boolean success = service.actualizarReserva(reserva);

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
