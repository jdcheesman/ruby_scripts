require_relative 'PLSQLProc'
require_relative 'LogError'
require 'set'


class ProcParser
    DATE_SLICE = 0 # not used
    TIME_SLICE = 1
    LOG_LEVEL_SLICE = 2 # not used
    THREAD_SLICE = 3
    JAVA_ID_SLICE = 4
    PLSQL_SLICE = 5

    attr :filename
    attr_accessor :allprocs
    attr_accessor :errors
    attr_accessor :errorcount
    attr_accessor :nodename



    def initialize(directory, filename)
        directory = directory + "\\" if directory !~ /\\$/
        @filename = directory + filename
        @nodename = filename.sub(/\.log$/, "").chomp.strip
        @allprocs = Hash[]
        @errors = Set[]
        @errorcount = 0
    end

    ########################################################
    #
    # Parse a log file to get elapsed times for PLSQL calls
    #
    # Example line:
    # 2013-01-24 09:23:15.552 [INFO] [AJPRequestHandler-ApplicationServerThread-24] es.uned.portal.gaia.matriculapas.portlet.EnvioCartasPortlet.renderBody===> ***INICIO DE EJECUCION --- EnvioCartasPortlet Pas***
    #
    # Assumptions:
    # * format of start and end of log messages for PLSQL calls
    # * Single day logs (in decade 2010-2019)
    # * thread identified by "AJPRequestHandler-ApplicationServerThread-"
    ########################################################
    def parse()
        f = File.open(@filename, "r")
        inicioProc_StartTime = Hash[]
        plSqlData = Hash[]
        linecounter = 0
        previouserror = LogError.new("", "", 1)
        f.each_line do|line|
            linecounter += 1
            if line =~ /^201[3..9]/ and line =~ /AJPRequestHandler-ApplicationServerThread-/
                lineData = line.split(' ', 6)
                normalisedTime = get_normalised_time(lineData[TIME_SLICE])

                if line =~/\[ERROR\]/
                    le = LogError.new(lineData[TIME_SLICE], lineData[PLSQL_SLICE], normalisedTime)
                    if ! le.same?(previouserror)
                        @errorcount += 1
                        @errors.add(le)
                    end
                    previouserror = le
                end

                thread_java_id = lineData[THREAD_SLICE] + "#" + lineData[JAVA_ID_SLICE]
                if (lineData[PLSQL_SLICE].downcase =~ /inicio procedimiento/ or lineData[PLSQL_SLICE] =~ /\{call/ or lineData[PLSQL_SLICE] =~ /\{?=call/)
                    inicioProc_StartTime[thread_java_id] = normalisedTime
                    plSqlData[thread_java_id] = lineData[PLSQL_SLICE]
                elsif (lineData[PLSQL_SLICE].downcase =~ /fin procedimiento/)
                    if inicioProc_StartTime[thread_java_id] == nil
                        # experience shows following is never called, although is expected for transactions @ midnight
                        printf("%s missing start marker @ [%s]\n", lineData[JAVA_ID_SLICE], lineData[TIME_SLICE])
                    else
                        log_pl_sql(lineData[JAVA_ID_SLICE], plSqlData[thread_java_id], (normalisedTime - inicioProc_StartTime[thread_java_id]), lineData[TIME_SLICE])
                    end
                end
            end
        end
        f.close
        linecounter
    end


    def get_normalised_time(string_time)
        # Expected: 09:23:15.552
        time = /[0]?(\d+):[0]?(\d+):[0]?(\d+)\.[0]?[0]?(\d+)/.match(string_time)
        hours = time[1].to_i
        minutes = time[2].to_i
        sec = time[3].to_i
        ms = time[4].to_i
        (hours * 60 * 60 * 1000) + (minutes * 60 * 1000) + (sec * 1000) + ms
    end

    def get_pl_sql(pl_sql_key)
        if @allprocs[pl_sql_key] == nil
            p = PLSQLProc.new(pl_sql_key)
        else
            p = @allprocs[pl_sql_key]
        end
        p
    end

    def log_pl_sql(java_id, plsql, endTime, time)
        # note thread id is NOT part of key for output data:
        p = get_pl_sql(java_id)
        p.add_call(endTime, plsql, time)
        @allprocs[java_id] = p
    end



end