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
        String[] columnNames = {"Código", "Cliente", "Empleado", "Tipo Habitación", "Habitación", "Tipo Reserva", "Tiempo Reservado", "Total", "Estado", "Fecha reserva", "Fecha entrada", "Fecha salida", "Fecha creado", "Fecha actualizado"};
        Object[] data = new Object[columnNames.length];
        List<Reserva> reservas = service.listarReservas(data);

        response.setSuccess(true);
        response.setMessage("Listar reservas");
        response.setResult(reservas);

        return response;
    }

    public void crearReserva(Reserva reserva) {
        service.crearReserva(reserva);
    }

    public void actualizarReserva(Reserva reserva) {
        service.actualizarReserva(reserva);
    }

}
