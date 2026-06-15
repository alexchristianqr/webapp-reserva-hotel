package models;

public class Cliente extends Persona {

    private int idCliente;
    private int idUsuario;
    private String username; // correo de acceso del usuario asociado
    private String password; // solo se usa al crear la cuenta

    public Cliente() {
    }

    public Cliente(Cliente cliente) {
        super(cliente.getNroDocumento(), cliente.getNombre(), cliente.getApellidos(), cliente.getSexo(), cliente.getEdad(), cliente.getTelefono(), cliente.getEstado(), cliente.getFechaCreado(), cliente.getFechaActualizado(),cliente.getIdPersona());
        this.idCliente = cliente.getIdCliente();
        this.idUsuario = cliente.getIdUsuario();
        this.username = cliente.getUsername();
        this.password = cliente.getPassword();
    }

    public int getIdCliente() {
        return idCliente;
    }

    public void setIdCliente(int idCliente) {
        this.idCliente = idCliente;
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
