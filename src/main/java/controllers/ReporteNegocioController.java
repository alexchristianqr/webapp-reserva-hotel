package controllers;

import core.BaseController;
import core.services.ResponseService;
import models.ReporteDashboard;
import services.ReporteNegocioService;

public class ReporteNegocioController extends BaseController<ReporteDashboard, ReporteNegocioService> {

    public ReporteNegocioController() {
        service = new ReporteNegocioService();
    }

    public ResponseService<ReporteDashboard> obtenerDashboard(String desde, String hasta) {
        ResponseService<ReporteDashboard> response = new ResponseService<>();

        try {
            ReporteDashboard dashboard = service.obtenerDashboard(desde, hasta);
            response.setSuccess(true);
            response.setMessage("Procesado correctamente");
            response.setResult(dashboard);
        } catch (IllegalArgumentException e) {
            response.setSuccess(false);
            response.setMessage(e.getMessage());
        }

        return response;
    }
}
