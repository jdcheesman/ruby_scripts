require_relative 'PLSQLProc'
require 'set'

class ProcParser
    DATE_SLICE = 0 # not used
    TIME_SLICE = 1
    LOG_LEVEL_SLICE = 2 # not used
    THREAD_SLICE = 3
    JAVA_ID_SLICE = 4
    PLSQL_SLICE = 5

    BAD_RESULT_TIME_THRESHOLD = 5 * 1000


    attr :allprocs
    attr :missing

    def initialize()
        @allprocs = Hash[]
        @missing = Set[]
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
    def parse(infile)
        f = File.open(infile, "r")
        inicioProc_StartTime = Hash[]
        plSqlData = Hash[]
        previousTime = -1 # used for console "doing something" message
        linecounter = 0 # used for console "doing something" message

        f.each_line do|line|
            linecounter += 1
            if line =~ /^201[3..9]/ and line =~ /AJPRequestHandler-ApplicationServerThread-/
                lineData = line.split(' ', 6)
                normalisedTime = get_normalised_time(lineData[TIME_SLICE])
                #send something to console to show we're working
                if (normalisedTime - previousTime) > (60 * 60 * 1000)
                    printf("[%d]\t%s\n", linecounter, lineData[TIME_SLICE])
                    previousTime = normalisedTime
                end

                thread_java_id = lineData[THREAD_SLICE] + "#" + lineData[JAVA_ID_SLICE]
                if (lineData[PLSQL_SLICE].downcase =~ /inicio procedimiento/ or lineData[PLSQL_SLICE] =~ /\{call/ or lineData[PLSQL_SLICE] =~ /\{?=call/)
                    inicioProc_StartTime[thread_java_id] = normalisedTime
                    plSqlData[thread_java_id] = lineData[PLSQL_SLICE]
                elsif (lineData[PLSQL_SLICE].downcase =~ /fin procedimiento/)
                    if inicioProc_StartTime[thread_java_id] == nil
                        @missing.add(lineData[JAVA_ID_SLICE])
                    else
                        log_pl_sql(lineData[JAVA_ID_SLICE], plSqlData[thread_java_id], (normalisedTime - inicioProc_StartTime[thread_java_id]))
                    end
                end
            end
        end
        f.close
        printf("%d lines processed.\n\n", linecounter)
    end

    def createCSV(outfile)
        fout = File.open(outfile, "w")
        fout.write("Clase Java\tMetodo\tNum Llamadas\tTotal (ms)\tMedio (ms)\tPeor (ms)\tDatos Peor Llamada\n")
        print("calls\ttotal\tavg\tworst\tbad\tname\n")
        @allprocs.each_key do |key|
            proc = @allprocs[key]
            @missing.delete?(proc.name)
            avg = proc.totaltime / proc.calls
            slicedJava = /([a-zA-Z\.]+)\.([a-zA-Z]+)/.match(proc.name)
            fout.write(slicedJava[1]) # class name
            fout.write("\t")
            fout.write(slicedJava[2]) # method
            fout.write("\t")
            fout.write(proc.calls)
            fout.write("\t")
            fout.write(proc.totaltime)
            fout.write("\t")
            fout.write(avg)
            fout.write("\t")
            fout.write(proc.worst)
            fout.write("\t")
            fout.write(proc.plSqlData)
            fout.write("\n")
            if avg > BAD_RESULT_TIME_THRESHOLD or proc.worst > BAD_RESULT_TIME_THRESHOLD
                overThreshold = " !"
            else
                overThreshold = "  "
            end
            printf("%d\t%d\t%d\t%d\t%s\t%s\n", proc.calls, proc.totaltime, avg, proc.worst, overThreshold, proc.name)
        end
        fout.close
    end

    def show_missing()
        if @missing.empty?
            print("\nAll procedures have start and end markers.\n")
        else
            print("\nFollowing procedures are missing end marker (no time calculated):\n")
            @missing.each do | key |
                printf("%s\n", key)
            end
        end
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

    def log_pl_sql(java_id, plsql, endTime)
        # note thread id is NOT part of key for output data:
        p = get_pl_sql(java_id)
        p.add_call(endTime, plsql)
        @allprocs[java_id] = p
    end



end