package controllers;

import core.BaseController;
import core.services.ResponseService;
import java.util.List;
import models.Comprobante;
import services.ComprobanteService;

public class ComprobanteController extends BaseController<Comprobante, ComprobanteService> {

    public ComprobanteController() {
        lista.clear();
        service = new ComprobanteService();
    }

    public ResponseService<List<Comprobante>> listarComprobantes(int idReserva) {
        ResponseService<List<Comprobante>> response = new ResponseService<>();
        List<Comprobante> comprobantes = service.listarComprobantes(idReserva);
        response.setSuccess(true);
        response.setMessage(comprobantes.isEmpty() ? "Sin comprobantes emitidos" : "Procesado correctamente");
        response.setResult(comprobantes);
        return response;
    }

    public ResponseService<Boolean> generarComprobante(int idReserva, int idEmpleado, int tipoComprobante) {
        ResponseService<Boolean> response = new ResponseService<>();
        try {
            Boolean success = service.generarComprobante(idReserva, idEmpleado, tipoComprobante);
            response.setSuccess(success);
            response.setMessage(success ? "Comprobante generado correctamente" : "Error al generar comprobante");
        } catch (RuntimeException e) {
            response.setSuccess(false);
            response.setMessage(e.getMessage());
        }
        return response;
    }
}
