package models;

public class Empleado extends Persona {

    private int idEmpleado;
    private int idUsuario;
    private int idPerfil;
    private double sueldo;
    private String username; // correo de acceso del usuario asociado
    private String password; // solo se usa al crear la cuenta

    public Empleado() {
    }

    public Empleado(Empleado empleado) {
        super(empleado.getNroDocumento(), empleado.getNombre(), empleado.getApellidos(), empleado.getSexo(), empleado.getEdad(), empleado.getTelefono(), empleado.getEstado(), empleado.getFechaCreado(), empleado.getFechaActualizado(), empleado.getIdPersona());
        this.idPerfil = empleado.getIdPerfil();
        this.sueldo = empleado.getSueldo();
    }

    public int getIdPerfil() {
        return idPerfil;
    }

    public void setIdPerfil(int idPerfil) {
        this.idPerfil = idPerfil;
    }

    public int getIdEmpleado() {
        return idEmpleado;
    }

    public void setIdEmpleado(int idEmpleado) {
        this.idEmpleado = idEmpleado;
    }

    public double getSueldo() {
        return sueldo;
    }

    public void setSueldo(double sueldo) {
        this.sueldo = sueldo;
    }

    public int getIdUsuario() {
        return idUsuario;
    }

    public void setIdUsuario(int idUsuario) {
        this.idUsuario = idUsuario;
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }

}
