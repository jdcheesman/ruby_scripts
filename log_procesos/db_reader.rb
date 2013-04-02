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
if db != "PRE" and db != "PRO"
    raise "Invalid command line arguments: db_reader [PRE | PRO] <dd/mm/yyyy>"
end

date = ARGV[1]
if date == nil or date !~ /^[0-9]{2}\/[0-9]{2}\/[0-9]{4}$/
    raise "Invalid command line arguments: db_reader [PRE | PRO] <dd/mm/yyyy>"
end

config = YAML.load_file(File.join(File.dirname(__FILE__), 'config.yaml'))


query = "select /*+ index(fec_ini IDX_LOGPROC_FECINI ) */  " +
    "A.PROCEDIMIENTO, A.FEC_INI, A.DURACION, " +
    "A.CAMPO_ID || '=' || A.VALOR_ID || '#' || A.PARAMETROS_E || '#' || A.PARAMETROS_S parametros, " +
    "A.ERRCODE, A.LITERR, A.TIPOERR " +
    "from POSGRADO_PRO.log_procesos a " +
    "where " +
    "fec_ini >= to_date( '" + date + "' || ' 00:00:00', 'DD/MM/YYYY HH24:MI:SS') " +
    "and     fec_ini <=  to_date( '" + date + "' || ' 23:59:59', 'DD/MM/YYYY HH24:MI:SS') " +
    "order by fec_ini asc"

procs = Hash[]

database = "database_" + db.downcase
oci = OCI8.new(config[database]['user'], config[database]['pwd'], config[database]['SID'])

oci.exec(query) do |record|
    proc = record[0]
    if procs[proc] == nil
        procs[proc] = MyProc.new(proc)
    end
    procs[proc].add_call(record[2], record[3], record[1])
end

procs.each_key do | key |
    puts procs[key].to_json
end

filename = getfilename()
puts filename
writer = OutputWriter.new(filename, date)
writer.write_xlsx(procs)

