# set nls_lang before requiring OCI8:
ENV['NLS_LANG'] = 'SPANISH_SPAIN.WE8ISO8859P15'

# INSTALL:

# install ruby, devkit, oracle client including sqlplus and sdk components
# SET ORACLE_HOME=<path to client>
# set path=<path to client>;%path%;

# gem install -r ruby-oci8

require 'rubygems'
require 'OCI8'

require_relative 'Proc'
require_relative 'OutputWriter'


def getfilename()
    time = Time.new
    "log_procesos_" + time.year.to_s + time.month.to_s + time.day.to_s + "-" +  time.hour.to_s + time.min.to_s + ".xlsx"
end




db = ARGV[0]
if db != "PRE" and db != "PRO" and db != "PRU"
    raise "Invalid command line arguments: db_reader [PRE | PRO | PRU] <dd-mm-yyyy>"
end

date = ARGV[1]
if date == nil or date !~ /^[0-9]{2}-[0-9]{2}-[0-9]{4}$/
    raise "Invalid command line arguments: db_reader [PRE | PRO | PRU] <dd-mm-yyyy>"
end

config = YAML.load_file(File.join(File.dirname(__FILE__), 'config.yaml'))



query_old = "select /*+ INDEX (FEC_INI IDX_LOGPROC_FECINI ) */  " +
    "A.PROCEDIMIENTO, to_char(A.FEC_INI), A.DURACION, " +
    "A.CAMPO_ID || '=' || A.VALOR_ID || '#' || A.PARAMETROS_E || '#' || A.PARAMETROS_S parametros, " +
    "A.ERRCODE, A.LITERR, A.TIPOERR " +
    "from POSGRADO_PRO.log_procesos a " +
    "where " +
    "FEC_INI >= to_date( '" + date + "' || ' 00:00:00', 'DD/MM/YYYY HH24:MI:SS') " +
    "and     FEC_INI <=  to_date( '" + date + "' || ' 23:59:59', 'DD/MM/YYYY HH24:MI:SS') "
     #+ "order by fec_ini asc"


query = "SELECT PROCEDIMIENTO, TO_CHAR(MAX_DURACION,'999999999'), TO_CHAR(AVG_DURACION,'999999.999'), " +
    "TO_CHAR(MIN_DURACION,'999999999'), LLAMADAS FROM V_LOGGED_PROCS where fec_ini='" + date + "'"

query = "SELECT A.PROCEDIMIENTO,
  TO_CHAR(A.MAX_DURACION,'999999999') MAX_DIA, TO_CHAR(A.AVG_DURACION,'999999.999') AVG_DIA,
  TO_CHAR(A.MIN_DURACION,'999999999') MIN_DIA, A.LLAMADAS LLAMADAS_DIA,
  TO_CHAR(B.MAX_DURACION,'999999999') MAX_WK, TO_CHAR(B.AVG_DURACION,'999999.999') AVG_WK,
  TO_CHAR(B.MIN_DURACION,'999999999') MIN_WK, B.LLAMADAS LLAMADAS_WK,
  CASE WHEN A.AVG_DURACION>0 THEN TO_CHAR(((A.AVG_DURACION - B.AVG_DURACION) / A.AVG_DURACION)*100, '999999.999') || '%'
  ELSE '0%' END PERCENT_CHANGE
FROM V_LOGGED_PROCS A, V_WEEK_AVG_LOGGED_PROCS B
where A.fec_ini='" + date + "' AND
A.PROCEDIMIENTO = B.PROCEDIMIENTO"

procs = Hash[]

database = "database_" + db.downcase
oci = OCI8.new(config[database]['user'], config[database]['pwd'], config[database]['SID'])


oci.exec(query) do |record|

    proc = record[0]
    #(name, worst, avg, best, calls)
    procs[proc] = MyProc.new(proc, record[1], record[2], record[3], record[4])
    procs[proc].worst_wk = record[5]
    procs[proc].avg_wk = record[6]
    procs[proc].best_wk = record[7]
    procs[proc].calls_wk = record[8]
    procs[proc].percent_change = record[9]
    printf("%s\n", proc)
end
oci.logoff

oci = OCI8.new(config[database]['user'], config[database]['pwd'], config[database]['SID'])
procs.each_key do | key |
    proc = procs[key]
    query2 = "SELECT A.ID, A.PARAMETROS_E, A.PARAMETROS_S, A.FEC_INI " +
                "FROM POSGRADO_PRO.LOG_PROCESOS A WHERE " +
                "A.PROCEDIMIENTO='" + key + "' and A.DURACION='" +  proc.worst.to_s.chomp.strip + "' " +
                "and to_char(a.fec_ini, 'DD-MM-YYYY')='" + date + "'"
    oci.exec(query2) do |record|
        # should only ever enter here once!
        #id_worst, callplSqlData_E, callplSqlData_S, time
        proc.add_worst_data(record[0], record[1], record[2], record[3].to_s)
    end
    puts procs[key].to_json
end
oci.logoff

filename = getfilename()
puts filename
writer = OutputWriter.new(filename, date)
writer.write_xlsx(procs)

