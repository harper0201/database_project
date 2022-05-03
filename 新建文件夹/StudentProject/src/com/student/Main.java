package com.student;

import java.sql.*;

import oracle.jdbc.OracleTypes;
import oracle.jdbc.pool.OracleDataSource;

import java.io.IOException;
import java.io.OutputStream;
import java.net.InetSocketAddress;

import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpHandler;
import com.sun.net.httpserver.HttpServer;
import com.sun.net.httpserver.Headers;
import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.net.InetSocketAddress;
import java.net.URI;
import java.net.URLDecoder;
import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;
import java.sql.Date;
import java.util.*;

import com.google.gson.*;

public class Main {

    private static final String HOSTNAME = "localhost";
    private static final int PORT = 8080;
    private static final int BACKLOG = 1;

    private static final String HEADER_ALLOW = "Allow";
    private static final String HEADER_CONTENT_TYPE = "Content-Type";

    private static final Charset CHARSET = StandardCharsets.UTF_8;

    private static final int STATUS_OK = 200;
    private static final int STATUS_METHOD_NOT_ALLOWED = 405;

    private static final int NO_RESPONSE_LENGTH = -1;

    private static final String METHOD_GET = "GET";
    private static final String METHOD_OPTIONS = "OPTIONS";
    private static final String ALLOWED_METHODS = METHOD_GET + "," + METHOD_OPTIONS;

    private static Map<String, List<String>> getRequestParameters(final URI requestUri) {
        final Map<String, List<String>> requestParameters = new LinkedHashMap<>();
        final String requestQuery = requestUri.getRawQuery();
        if (requestQuery != null) {
            final String[] rawRequestParameters = requestQuery.split("[&;]", -1);
            for (final String rawRequestParameter : rawRequestParameters) {
                final String[] requestParameter = rawRequestParameter.split("=", 2);
                final String requestParameterName = decodeUrlComponent(requestParameter[0]);
                requestParameters.putIfAbsent(requestParameterName, new ArrayList<>());
                final String requestParameterValue = requestParameter.length > 1 ? decodeUrlComponent(requestParameter[1]) : null;
                requestParameters.get(requestParameterName).add(requestParameterValue);
            }
        }
        return requestParameters;
    }

    private static String decodeUrlComponent(final String urlComponent) {
        try {
            return URLDecoder.decode(urlComponent, CHARSET.name());
        } catch (final UnsupportedEncodingException ex) {
            throw new InternalError(ex);
        }
    }

    public static String makeErrorReturn(String msg) {
        return "{\"code\": \"422\", \"errMsg\": \""+msg+"\"}";
    }

    private static void addValueToJSON(JsonObject obj, String propertyName, Object value){
        if (value == null) {
            obj.add(propertyName, JsonNull.INSTANCE);
        } else if (value instanceof Number) {
            obj.addProperty(propertyName, (Number)value);
        } else if (value instanceof String) {
            obj.addProperty(propertyName, (String)value);
        } else if (value instanceof java.sql.Date) {
            // Not clear how you want dates to be represented in JSON.
            // Perhaps use SimpleDateFormat to convert them to a string?
            // I'll leave it up to you to finish this off.
            obj.addProperty(propertyName, value.toString());
        } else {
            // Some other type of value.  You can of course add handling
            // for extra types of values that you get, but it's worth
            // keeping this line at the bottom to ensure that if you do
            // get a value you are not expecting, you find out about it.
            obj.addProperty(propertyName, value.toString());
        }
    }

    public static JsonArray GetJSONDataFromResultSet(ResultSet rs) throws SQLException {
        ResultSetMetaData metaData = rs.getMetaData();
        int count = metaData.getColumnCount();
        String[] columnName = new String[count];

        JsonArray jsonArray = new JsonArray();
        while(rs.next()) {
            JsonObject jsonObject = new JsonObject();
            for (int i = 1; i <= count; i++){
                columnName[i-1] = metaData.getColumnLabel(i);
                addValueToJSON(jsonObject, columnName[i-1], rs.getObject(i));
            }
            jsonArray.add(jsonObject);
        }
        return jsonArray;
    }

    public static String getParam(Map<String, List<String>> params, String key) {
        List<String> actionParam = params.get(key);
        if (actionParam == null || actionParam.size() != 1) {
            return null;
        }
        return actionParam.get(0);
    }

    public static String studentHandler(Connection conn, Map<String, List<String>> params, String action)throws SQLException {
        String bno = getParam(params, "bno");
        if (bno == null) return makeErrorReturn("incorrect B#");
        String classid = null;
        if (!action.equals("delete")) {
            classid = getParam(params, "classid");
            if (classid == null) return makeErrorReturn("incorrect classid");
        }
        // call stored procedure
        CallableStatement cs;
        if (action.equals("delete")) {
            // bno only
            cs = conn.prepareCall(
                    "begin ? := MY_SERVER.delete_student_func(?); end;");

            cs.setString(2, bno);
        }
        else {
            if (action.equals("enroll")) {
                cs = conn.prepareCall(
                        "begin ? := MY_SERVER.enroll_class_func(?,?); end;");
            }
            else {
                cs = conn.prepareCall(
                        "begin ? := MY_SERVER.drop_class_func(?,?); end;");
            }

            // bno and classid
            cs.setString(2, bno);
            cs.setString(3, classid);
        }

        //register the out parameter (the first parameter)
        cs.registerOutParameter(1, OracleTypes.VARCHAR);

        cs.execute();
        String rs = (String)cs.getObject(1);
        if (rs.equals("SUCCESS")) {
            return "{\"code\": 0}";
        }
        else {
            return "{\"code\": 1, \"errMsg\":\"" + rs + "\"}";
        }
    }

    public static String queryHandler(Connection conn, Map<String, List<String>> params) throws SQLException {
        Set<String> s  = new HashSet<String>(Arrays.asList("logs", "classes", "course_credit", "courses",
                "enrollments", "logs", "prerequisites", "score_grade", "students"));

        String table = getParam(params, "table");
        if (table == null) return makeErrorReturn("incorrect table name null");

        table = table.toLowerCase();
        if (!s.contains(table)) {
            return makeErrorReturn("incorrect table name");
        }
        // call stored procedure
        CallableStatement cs = conn.prepareCall(
                "begin ? := MY_SERVER.show_" + table + "_ref(); end;");

        //register the out parameter (the first parameter)
        cs.registerOutParameter(1, OracleTypes.CURSOR);
        cs.execute();
        ResultSet rs = (ResultSet)cs.getObject(1);

        JsonArray arr = GetJSONDataFromResultSet(rs);

        return arr.toString();
    }

    public static String checkHandler(Connection conn, Map<String, List<String>> params) throws Exception {

        String classid = getParam(params, "classid");
        if (classid == null) return makeErrorReturn("incorrect classid");

        // call stored procedure
        CallableStatement cs = conn.prepareCall(
                "begin ? := MY_SERVER.check_class_func(?); end;");
        cs.setString(2, classid);
        //register the out parameter (the first parameter)
        cs.registerOutParameter(1, OracleTypes.CURSOR);
        cs.execute();
        ResultSet rs = (ResultSet)cs.getObject(1);

        JsonArray arr = GetJSONDataFromResultSet(rs);

        return arr.toString();
    }

    public static String requestHandler(Connection conn, Map<String, List<String>> params) throws Exception {
        String action = getParam(params, "action");
        if (action == null) {
            return makeErrorReturn("incorrect action");
        }

        return switch (action) {
                case "query" -> queryHandler(conn, params);
                case "drop" -> studentHandler(conn, params, "drop");
                case "enroll" -> studentHandler(conn, params, "enroll");
                case "delete" -> studentHandler(conn, params, "delete");
                case "check" -> checkHandler(conn, params);
                default -> makeErrorReturn("incorrect action");
        };

    }

    public static void main(String[] args) throws Exception {

        //Connecting to Oracle server.
        OracleDataSource ds = new oracle.jdbc.pool.OracleDataSource();
        ds.setURL("jdbc:oracle:thin:@castor.cc.binghamton.edu:1521:acad111");
        Connection conn = ds.getConnection("xhong4", "hxx2073125");

        final HttpServer server = HttpServer.create(new InetSocketAddress(HOSTNAME, PORT), BACKLOG);
        server.createContext("/api", he -> {
            try {
                final Headers headers = he.getResponseHeaders();
                final String requestMethod = he.getRequestMethod().toUpperCase();
                switch (requestMethod) {
                    case "POST":
                        final Map<String, List<String>> requestParameters = getRequestParameters(he.getRequestURI());
                        // do something with the request parameters
                        final String responseBody;
                        try {
                            responseBody = requestHandler(conn, requestParameters);
                            headers.set(HEADER_CONTENT_TYPE, String.format("application/json; charset=%s", CHARSET));
                            final byte[] rawResponseBody = responseBody.getBytes(CHARSET);
                            he.sendResponseHeaders(STATUS_OK, rawResponseBody.length);
                            he.getResponseBody().write(rawResponseBody);
                        } catch (Exception e) {
                            e.printStackTrace();
                        }

                        break;
                    default:
                        headers.set(HEADER_ALLOW, ALLOWED_METHODS);
                        he.sendResponseHeaders(STATUS_METHOD_NOT_ALLOWED, NO_RESPONSE_LENGTH);
                        break;
                }
            } finally {
                he.close();
            }
        });
        server.start();
    }
}

