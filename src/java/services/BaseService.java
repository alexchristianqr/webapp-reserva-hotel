package services;

import core.services.MysqlDBService;
//import java.sql.Connection;

public abstract class BaseService {
    public MysqlDBService db;
    public String querySQL_1, querySQL_2, querySQL_3, querySQL_4;
//    public Connection conn = null;
}
