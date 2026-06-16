package services;

import core.BaseService;
import core.services.MysqlDBService;
import core.utils.PasswordUtil;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

import models.Cliente;

public class ClienteService extends BaseService {

    // Perfil de cliente por defecto (ver tabla clientes_perfiles del db_hotel.sql)
    private static final int PERFIL_CLIENTE_POR_DEFECTO = 1;

    public ClienteService() {
        db = new MysqlDBService();
    }

    public List<Cliente> listarClientes(String buscar) {
        List<Cliente> clientes = new ArrayList<>();

        querySQL_1 = "SELECT c.id, c.id_usuario, u.username, p.nombre, p.apellido, p.tipo_documento, p.nrodocumento, p.edad, p.sexo, p.telefono, c.estado, c.fecha_creado, c.fecha_actualizado "
                + "FROM clientes c JOIN personas p ON p.id = c.id_persona LEFT JOIN usuarios u ON u.id = c.id_usuario";
        Object[] parametrosSQL_1 = {};

        // Búsqueda parametrizada (SQL LIKE) por nombre, apellido o documento
        if (buscar != null && !buscar.isBlank()) {
            querySQL_1 += " WHERE p.nombre LIKE ? OR p.apellido LIKE ? OR p.nrodocumento LIKE ?";
            String like = "%" + buscar.trim() + "%";
            parametrosSQL_1 = new Object[]{like, like, like};
        }

        querySQL_1 += " ORDER BY c.id DESC";
        ResultSet rs = db.queryConsultar(querySQL_1, parametrosSQL_1);

        try {
            while (rs.next()) {
                Cliente cliente = new Cliente();
                cliente.setIdCliente(rs.getInt("id"));
                cliente.setIdUsuario(rs.getInt("id_usuario"));
                cliente.setUsername(rs.getString("username"));
                cliente.setNombre(rs.getString("nombre"));
                cliente.setApellidos(rs.getString("apellido"));
                cliente.setTipoDocumento(rs.getInt("tipo_documento"));
                cliente.setNroDocumento(rs.getString("nrodocumento"));
                cliente.setEdad(rs.getString("edad"));
                cliente.setSexo(rs.getString("sexo"));
                cliente.setTelefono(rs.getString("telefono"));
                cliente.setEstado(rs.getString("estado"));
                cliente.setFechaCreado(rs.getString("fecha_creado"));
                cliente.setFechaActualizado(rs.getString("fecha_actualizado"));

                clientes.add(cliente);
            }

            return clientes;
        } catch (SQLException ex) {
            throw new RuntimeException(ex);
        } finally {
            db.cerrarConsulta();
        }
    }

    // Crea, en una sola transacción, la cadena usuario -> persona -> cliente.
    // El cliente queda enlazado a un usuario (rol 'cliente') tal como exige el esquema.
    public Boolean crearCliente(Cliente cliente) {
        validarDatosCuenta(cliente);

        boolean autoCommitOriginal = db.getAutoCommit();
        db.setAutoCommit(false);
        try {
            // 1) Cuenta de acceso (usuarios)
            querySQL_1 = "INSERT INTO usuarios (nombres, apellidos, rol, username, pwd, estado) VALUES (?,?,'cliente',?,?,?)";
            Object[] parametrosSQL_1 = {
                cliente.getNombre(), cliente.getApellidos(),
                cliente.getUsername(), PasswordUtil.hashear(cliente.getPassword()),
                estadoOActivo(cliente.getEstado())
            };
            int idUsuario = db.queryInsertar(querySQL_1, parametrosSQL_1);

            // 2) Datos personales (personas)
            querySQL_2 = "INSERT INTO personas (nombre, apellido, tipo_documento, nrodocumento, sexo, edad, telefono, estado) VALUES (?,?,?,?,?,?,?,?)";
            Object[] parametrosSQL_2 = {
                cliente.getNombre(), cliente.getApellidos(), cliente.getTipoDocumento(),
                cliente.getNroDocumento(), cliente.getSexo(), cliente.getEdad(),
                cliente.getTelefono(), estadoOActivo(cliente.getEstado())
            };
            int idPersona = db.queryInsertar(querySQL_2, parametrosSQL_2);

            // 3) Cliente enlazando persona + usuario + perfil
            querySQL_3 = "INSERT INTO clientes (id_persona, id_usuario, id_cliente_perfil, empresa, estado) VALUES (?,?,?,?,?)";
            Object[] parametrosSQL_3 = {
                idPersona, idUsuario, PERFIL_CLIENTE_POR_DEFECTO,
                cliente.getNombre() + ' ' + cliente.getApellidos(), estadoOActivo(cliente.getEstado())
            };
            db.queryInsertar(querySQL_3, parametrosSQL_3);

            db.commit();
            return true;
        } catch (RuntimeException ex) {
            db.rollback();
            throw traducirError(ex);
        } finally {
            db.setAutoCommit(autoCommitOriginal);
            db.cerrarConsulta();
        }
    }

    // Actualiza persona + cliente y propaga el estado a la cuenta de usuario asociada.
    public Boolean actualizarCliente(Cliente cliente) {
        boolean autoCommitOriginal = db.getAutoCommit();
        db.setAutoCommit(false);
        try {
            querySQL_1 = "UPDATE personas SET nombre = ?, apellido = ?, tipo_documento = ?, nrodocumento = ?, edad = ?, sexo = ?, telefono = ?, estado = ?, fecha_actualizado = NOW() WHERE id = (SELECT id_persona FROM clientes c WHERE c.id = ?)";
            Object[] parametrosSQL_1 = {cliente.getNombre(), cliente.getApellidos(), cliente.getTipoDocumento(), cliente.getNroDocumento(), cliente.getEdad(), cliente.getSexo(), cliente.getTelefono(), cliente.getEstado(), cliente.getIdCliente()};
            db.queryActualizar(querySQL_1, parametrosSQL_1);

            querySQL_2 = "UPDATE clientes SET empresa = ?, estado = ?, fecha_actualizado = NOW() WHERE id = ?";
            Object[] parametrosSQL_2 = {cliente.getNombre() + ' ' + cliente.getApellidos(), cliente.getEstado(), cliente.getIdCliente()};
            db.queryActualizar(querySQL_2, parametrosSQL_2);

            // el estado del cliente manda sobre el de su cuenta de acceso
            querySQL_3 = "UPDATE usuarios SET estado = ?, fecha_actualizado = NOW() WHERE id = (SELECT id_usuario FROM clientes c WHERE c.id = ?)";
            Object[] parametrosSQL_3 = {cliente.getEstado(), cliente.getIdCliente()};
            db.queryActualizar(querySQL_3, parametrosSQL_3);

            db.commit();
            return true;
        } catch (RuntimeException ex) {
            db.rollback();
            throw traducirError(ex);
        } finally {
            db.setAutoCommit(autoCommitOriginal);
            db.cerrarConsulta();
        }
    }

    // Eliminación lógica: marca cliente, persona y usuario como inactivos (preserva FKs de reservas)
    public Boolean eliminarCliente(Cliente cliente) {
        boolean autoCommitOriginal = db.getAutoCommit();
        db.setAutoCommit(false);
        try {
            querySQL_1 = "UPDATE personas SET estado = 'inactivo', fecha_actualizado = NOW() WHERE id = (SELECT id_persona FROM clientes c WHERE c.id = ?)";
            db.queryActualizar(querySQL_1, new Object[]{cliente.getIdCliente()});

            querySQL_2 = "UPDATE clientes SET estado = 'inactivo', fecha_actualizado = NOW() WHERE id = ?";
            db.queryActualizar(querySQL_2, new Object[]{cliente.getIdCliente()});

            querySQL_3 = "UPDATE usuarios SET estado = 'inactivo', fecha_actualizado = NOW() WHERE id = (SELECT id_usuario FROM clientes c WHERE c.id = ?)";
            db.queryActualizar(querySQL_3, new Object[]{cliente.getIdCliente()});

            db.commit();
            return true;
        } catch (RuntimeException ex) {
            db.rollback();
            throw ex;
        } finally {
            db.setAutoCommit(autoCommitOriginal);
            db.cerrarConsulta();
        }
    }

    private void validarDatosCuenta(Cliente cliente) {
        if (cliente.getUsername() == null || cliente.getUsername().isBlank()
                || cliente.getPassword() == null || cliente.getPassword().isBlank()) {
            throw new IllegalArgumentException("Debe indicar correo y contraseña para la cuenta del cliente");
        }
    }

    private String estadoOActivo(String estado) {
        return (estado != null && !estado.isBlank()) ? estado : "activo";
    }

    // Traduce errores de BD comunes (correo duplicado) a mensajes entendibles para el operador.
    private RuntimeException traducirError(RuntimeException ex) {
        String msg = ex.getMessage() != null ? ex.getMessage().toLowerCase() : "";
        if (msg.contains("duplicate") && msg.contains("username")) {
            return new IllegalArgumentException("El correo ya está registrado para otra cuenta activa");
        }
        if (msg.contains("duplicate") && msg.contains("nrodocumento")) {
            return new IllegalArgumentException("Ya existe una persona con ese tipo y número de documento");
        }
        return ex;
    }
}
