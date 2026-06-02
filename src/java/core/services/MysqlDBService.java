package core.services;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import services.BaseService;

public class MysqlDBService extends BaseService {

    private static final String DRIVER_NAME = "com.mysql.cj.jdbc.Driver";
    private static final String URL = "jdbc:mysql://127.0.0.1:3306/db_hotel?useSSL=false&serverTimezone=UTC";
    private static final String USER = "root";
    private static final String PASSWORD = "";
    public Connection conn = null;
    public PreparedStatement stmt = null;

    public MysqlDBService() {
        this.conn = conectar();
        System.out.println("[MysqlDBService]: Conectado a la BD");
    }

    private Connection conectar() {
        try {
            Class.forName(DRIVER_NAME);
            Connection connection = DriverManager.getConnection(URL, USER, PASSWORD);
            System.out.println("Conexion exitosa a la base de datos");
            return connection;
        } catch (ClassNotFoundException e) {
            throw new RuntimeException("No se encontro el driver JDBC: " + DRIVER_NAME, e);
        } catch (SQLException e) {
            throw new RuntimeException("Error de conexion a la base de datos", e);
        }
    }

    public Connection getConnection() {
        return this.conn;
    }

    public void setConnection(Connection myConn) {
        this.conn = myConn;
    }

    public void desconectar() {
        if (conn != null) {

            System.out.println("[MysqlDBService.desconectar()]: ");

            try {
                conn.close();
            } catch (SQLException e) {
                throw new RuntimeException(e);
            }
        }
    }

    public void cerrarConsulta() {
        if (stmt != null) {

            // System.out.println("[MysqlDBService.cerrarConsulta()]: ");
            try {
                stmt.close();
            } catch (SQLException e) {
                throw new RuntimeException(e);
            }
        }
    }

    public void commit() {
        try {
            if (conn != null) {
                conn.commit();
                System.out.println("[MysqlDBService]: Transacción confirmada");
            }
        } catch (SQLException e) {
            throw new RuntimeException("Error al confirmar la transacción", e);
        }
    }

    public void rollback() {
        try {
            if (conn != null) {
                conn.rollback();
                System.out.println("[MysqlDBService]: Transacción revertida");
            }
        } catch (SQLException e) {
            throw new RuntimeException("Error al revertir la transacción", e);
        }
    }

    public void setAutoCommit(boolean autoCommit) {
        try {
            if (conn != null) {
                conn.setAutoCommit(autoCommit);
            }
        } catch (SQLException e) {
            throw new RuntimeException("Error al configurar auto-commit", e);
        }
    }

    public boolean getAutoCommit() {
        try {
            if (conn != null) {
                return conn.getAutoCommit();
            }
        } catch (SQLException e) {
            throw new RuntimeException("Error al obtener auto-commit", e);
        }
        return true; // Valor por defecto si no se puede obtener
    }

    private void bindParameters(PreparedStatement statement, Object[] parametros) throws SQLException {
        if (parametros == null || parametros.length == 0) {
            return;
        }

        for (int i = 0; i < parametros.length; i++) {
            statement.setObject(i + 1, parametros[i]);
        }
    }

    public ResultSet queryConsultar(String sql) {
        return queryConsultar(sql, new Object[0]);
    }

    public ResultSet queryConsultar(String sql, Object[] parametros) {
        try {
            conn = this.getConnection();

            stmt = conn.prepareStatement(sql);

            bindParameters(stmt, parametros);

            System.out.println("[MysqlDBService.queryConsultar()] QUERY: " + stmt.toString().replace("com.mysql.cj.jdbc.ClientPreparedStatement: ", ""));

            ResultSet rs = stmt.executeQuery();

            return rs;

        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }

    public int queryInsertar(String sql, Object[] parametros) {
        conn = this.getConnection();
        int newId = -1;

        try {
            stmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS);

            bindParameters(stmt, parametros);

            System.out.println("[MysqlDBService.queryInsertar()] QUERY: " + stmt.toString().replace("com.mysql.cj.jdbc.ClientPreparedStatement: ", ""));

            stmt.executeUpdate();
            ResultSet rs = stmt.getGeneratedKeys();

            if (rs.next()) {
                newId = rs.getInt(1);
                System.out.println("INSERT: new ID: " + newId);
            }

            rs.close();

            return newId;
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }

    public int queryActualizar(String sql, Object[] parametros) {
        try {
            stmt = conn.prepareStatement(sql);

            bindParameters(stmt, parametros);

            System.out.println("[MysqlDBService.queryActualizar()] QUERY: " + stmt.toString().replace("com.mysql.cj.jdbc.ClientPreparedStatement: ", ""));

            return stmt.executeUpdate();

        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }

    public int queryEliminar(String sql, Object[] parametros) {
        try {
            stmt = conn.prepareStatement(sql);

            bindParameters(stmt, parametros);

            System.out.println("[MysqlDBService.queryEliminar()] QUERY: " + stmt.toString().replace("com.mysql.cj.jdbc.ClientPreparedStatement: ", ""));

            return stmt.executeUpdate();

        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }
}
