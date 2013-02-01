require_relative 'PLSQLProc'
require_relative 'LogError'
require_relative 'Call'
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
    attr_accessor :calls



    def initialize(directory, filename)
        directory = directory + "\\" if directory !~ /\\$/
        @filename = directory + filename
        @nodename = filename.sub(/\.log$/, "").chomp.strip
        @allprocs = Hash[]
        @errors = Array[]
        @errorcount = 0
        @calls = Hash[]
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
        previouserror = LogError.new("", "", "abc.def", 1)
        hourminute = ""
        f.each_line do|line|
            linecounter += 1
            if line =~ /^201[3..9]/ and line =~ /AJPRequestHandler-ApplicationServerThread-/
                lineData = line.split(' ', 6)
                currentMinute = ProcParser.get_hour_minute(lineData[TIME_SLICE])
                if currentMinute != hourminute
                    hourminute = currentMinute
                    call = Call.new(currentMinute)
                else
                    call = @calls[currentMinute]
                end
                normalisedTime = get_normalised_time(lineData[TIME_SLICE])

                if line =~/\[ERROR\]/
                    le = LogError.new(lineData[TIME_SLICE], lineData[PLSQL_SLICE], lineData[JAVA_ID_SLICE], normalisedTime)
                    if le.same?(previouserror)
                        @errors.pop
                        le.code = previouserror.code
                    else
                        @errorcount += 1
                    end
                    @errors << le
                    previouserror = le
                    call.add_error()
                else
                    call.add_call()
                end
                # following logic assumes there are no overlapping PL/SQL calls in a given thread+method
                thread_java_id = lineData[THREAD_SLICE] + "#" + lineData[JAVA_ID_SLICE]
                if (lineData[PLSQL_SLICE].downcase =~ /inicio procedimiento/ or lineData[PLSQL_SLICE] =~ /\{call/ or lineData[PLSQL_SLICE] =~ /\{?=call/)
                    inicioProc_StartTime[thread_java_id] = normalisedTime
                    plSqlData[thread_java_id] = lineData[PLSQL_SLICE]
                elsif (lineData[PLSQL_SLICE].downcase =~ /fin procedimiento/)
                    if inicioProc_StartTime[thread_java_id] == nil
                        # experience shows following is never called, although is expected for transactions @ midnight
                        printf("%s missing start marker @ [%s]\n", lineData[JAVA_ID_SLICE], lineData[TIME_SLICE])
                    else
                        key = lineData[JAVA_ID_SLICE] + "#" + PLSQLProc.get_proc_name(PLSQLProc.clean_up_plSqlData(plSqlData[thread_java_id]))
                        # log_pl_sql(lineData[JAVA_ID_SLICE], plSqlData[thread_java_id], (normalisedTime - inicioProc_StartTime[thread_java_id]), lineData[TIME_SLICE])
                        log_pl_sql(key, plSqlData[thread_java_id], (normalisedTime - inicioProc_StartTime[thread_java_id]), lineData[TIME_SLICE])
                    end
                end
                @calls[currentMinute] = call
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

    def self.get_hour_minute(string_time)
        # Expected: 09:23:15.552
        time = /([0]?\d+):[0]?(\d+):[0]?(\d+)\.[0]?[0]?(\d+)/.match(string_time)
        hours = time[1]
        minutes = time[2].to_i
        if minutes < 15
            hours + ":00"
        elsif minutes < 30
            hours + ":15"
        elsif minutes < 45
            hours + ":30"
        else
            hours + ":45"
        end
    end


    def get_pl_sql(pl_sql_key)
        if @allprocs[pl_sql_key] == nil
            p = PLSQLProc.new(pl_sql_key)
        else
            p = @allprocs[pl_sql_key]
        end
        p
    end

    def log_pl_sql(pl_sql_key, plsql, endTime, time)
        # note thread id is NOT part of key for output data:
        p = get_pl_sql(pl_sql_key)
        p.add_call(endTime, plsql, time)
        @allprocs[pl_sql_key] = p
    end



end