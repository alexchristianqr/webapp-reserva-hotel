package controllers;

import core.BaseController;
import core.services.ResponseService;
import java.util.List;
import models.ReservaConsumo;
import services.ReservaConsumoService;

public class ReservaConsumoController extends BaseController<ReservaConsumo, ReservaConsumoService> {

    public ReservaConsumoController() {
        lista.clear();
        service = new ReservaConsumoService();
    }

    public ResponseService<List<ReservaConsumo>> listarConsumos(int idReserva) {
        ResponseService<List<ReservaConsumo>> response = new ResponseService<>();
        List<ReservaConsumo> consumos = service.listarConsumos(idReserva);
        response.setSuccess(true);
        response.setMessage(consumos.isEmpty() ? "Sin consumos registrados" : "Procesado correctamente");
        response.setResult(consumos);
        return response;
    }

    public ResponseService<Boolean> agregarConsumo(int idReserva, int idProducto, int cantidad) {
        ResponseService<Boolean> response = new ResponseService<>();
        try {
            Boolean success = service.agregarConsumo(idReserva, idProducto, cantidad);
            response.setSuccess(success);
            response.setMessage(success ? "Consumo agregado correctamente" : "Error al agregar consumo");
        } catch (RuntimeException e) {
            response.setSuccess(false);
            response.setMessage(e.getMessage());
        }
        return response;
    }

    public ResponseService<Boolean> eliminarConsumo(int idConsumo) {
        ResponseService<Boolean> response = new ResponseService<>();
        try {
            Boolean success = service.eliminarConsumo(idConsumo);
            response.setSuccess(success);
            response.setMessage(success ? "Consumo anulado correctamente" : "Error al anular consumo");
        } catch (RuntimeException e) {
            response.setSuccess(false);
            response.setMessage(e.getMessage());
        }
        return response;
    }
}
