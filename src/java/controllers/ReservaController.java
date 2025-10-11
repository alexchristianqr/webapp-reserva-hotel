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
            response.setMessage("Listado con éxito");
            response.setResult(reservas);
        }

        return response;
    }

    public void crearReserva(Reserva reserva) {
        service.crearReserva(reserva);
    }

    public void actualizarReserva(Reserva reserva) {
        service.actualizarReserva(reserva);
    }

}
