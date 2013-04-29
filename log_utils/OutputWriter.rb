require 'rubygems'
require 'simple_xlsx'

class File
    def tab_write(text)
        self.write(text)
        self.write("\t")
    end

    def end_line_write(text)
        self.write(text)
        self.write("\n")
    end

end

class OutputWriter
    BAD_RESULT_TIME_THRESHOLD = 5 * 1000

    attr :filename
    attr :filedate
    attr :worst_thread

    def initialize(filename, filedate)
        @filename = filename
        @filedate = filedate
        @worst_thread = Hash[]
    end

    def write_xlsx(alldata, errordata, calldata, missingdata, session_threads)
        SimpleXlsx::Serializer.new(@filename) do |doc|
            doc.add_sheet("DATOS") do |sheet|
                set_titles_llamadas(sheet)
                alldata.each_key do |key|
                    printf("\nWriting llamadas: %s\n", key)
                    add_node_data_llamadas(key, alldata[key], sheet)
                end
            end
            doc.add_sheet("ERRORES") do |sheet|
                set_titles_errores(sheet)
                errordata.each_key do |key|
                    printf("\nWriting errors: %s\n", key)
                    add_node_data_errores(key, errordata[key], sheet)
                end
            end
            doc.add_sheet("LLAMADAS") do |sheet|
                set_titles_calls(sheet)
                calldata.each_key do |key|
                    printf("\nWriting calls: %s\n", key)
                    add_node_data_calls(key, calldata[key], sheet)
                end
            end
            doc.add_sheet("MALFORMADO") do |sheet|
                set_titles_missing(sheet)
                missingdata.each_key do |key|
                    printf("\nWriting malformado: %s\n", key)
                    add_node_data_missing(key, missingdata[key], sheet)
                end
            end
            doc.add_sheet("HILOS") do | sheet |
                set_titles_hilos(sheet)
                session_threads.each_key do | key |
                    add_node_data_hilos(key, session_threads[key], sheet)
                end
            end
            doc.add_sheet("PEORES_HILOS") do | sheet |
                set_titles_peores(sheet)
                add_node_data_peores(sheet)
            end
        end
    end

    def set_titles_llamadas(sheet)
        sheet.add_row(["Nodo",
            "Clase Java",
            "Metodo",
            "Nombre proc",
            "Num Llamadas",
            "Total (ms)",
            "Medio (ms)",
            "Peor (ms)",
            "Mejor (ms)",
            "Datos Peor Llamada",
            "Hora Peor Llamada",
            "Datos Mejor Llamada",
            "Hora Mejor Llamada",
            "Fecha"])
    end


    def add_node_data_llamadas(nodename, data, sheet)
        print("calls\ttotal\tavg\tbest\tworst\tname\n")
        data.each_key do |key|
            proc = data[key]
            avg = proc.totaltime / proc.calls
            dd = proc.name.split('#')[0]
            slicedJava = /([a-zA-Z\.]+)\.([a-zA-Z_]+)/.match(dd)
            sheet.add_row([
                nodename,
                slicedJava[1], # class name
                slicedJava[2], # method
                PLSQLProc.get_proc_name(proc.plSqlData_worst),
                proc.calls,
                proc.totaltime,
                avg,
                proc.worst,
                proc.best,
                proc.plSqlData_worst,
                proc.worst_time,
                proc.plSqlData_best,
                proc.best_time,
                @filedate
                ])
            if avg > BAD_RESULT_TIME_THRESHOLD or proc.worst > BAD_RESULT_TIME_THRESHOLD
                printf("%d\t%d\t%d\t%d\t%s\t%s.%s\n", proc.calls, proc.totaltime, avg, proc.best, proc.worst, slicedJava[1], slicedJava[2])
            end
        end


    end

    def set_titles_errores(sheet)
        sheet.add_row(["Nodo",
            "Hora",
            "Clase Java",
            "Metodo",
            "Codigo",
            "Descripcion",
            "Fecha"])
    end

    def add_node_data_errores(nodename, data, sheet)
        data.each do |log_error|
            sheet.add_row([
                nodename,
                log_error.time,
                log_error.java_class,
                log_error.java_method,
                log_error.code,
                log_error.description,
                @filedate
                ])
        end
    end

    def set_titles_calls(sheet)
        sheet.add_row(["Nodo",
            "Hora",
            "Llamadas",
            "Errores",
            "Tiempo total",
            "Promedio",
            "Fecha"
            ])
    end

    def add_node_data_calls(nodename, data, sheet)
        data.each_key do |key|
            call = data[key]
            promedio = (call.total_time*1.0) / (call.call_count*1.0)
            sheet.add_row([
                nodename,
                call.minute,
                call.call_count,
                call.error_count,
                call.total_time,
                promedio,
                @filedate
                ])
        end
    end


    def set_titles_missing(sheet)
        sheet.add_row(["Nodo",
            "Clase Java",
            "Metodo",
            "PL/SQL",
            "Fecha"])
    end

    def add_node_data_missing(nodename, data, sheet)
        data.each do |log_missing|
            text = log_missing.split('#')
            java_method = text[0].split('.')[-1]
            java_class = text[0]
            java_class["." + java_method] = ""
            java_method["===>"] = ""
            sheet.add_row([
                nodename,
                java_class,
                java_method,
                text[1],
                @filedate
                ])
        end
    end

    def set_titles_hilos(sheet)
        sheet.add_row(["Nodo",
            "Clase Java",
            "Inicio",
            "Fin",
            "Elapsed",
            "Fecha"])
    end

    def add_node_data_hilos(nodename, data, sheet)
        worst_thread_time = Hash[]
        data.each_key do |key|
            data[key].each do | session_thread |
                elapsed = session_thread.elapsed
                if elapsed > 0
                    sheet.add_row([
                        nodename,
                        session_thread.id,
                        session_thread.real_start_time,
                        session_thread.real_end_time[-1],
                        elapsed,
                        @filedate
                    ])
                    if worst_thread_time[session_thread.id] == nil or
                        worst_thread_time[session_thread.id] < elapsed
                        worst_thread_time[session_thread.id] = elapsed
                        @worst_thread[session_thread.id] = session_thread
                    end
                end
            end
        end
    end

    def set_titles_peores(sheet)
        sheet.add_row([
            "Portlet",
            "Clase",
            "Msg",
            "Time",
            "Total elapsed",
            "Fecha"])
    end

    def add_node_data_peores(sheet)
        @worst_thread.each_key do |portlet|
            counter = 0
            thread = @worst_thread[portlet]
            thread.msgs.each do | msg |
                thread.javas[counter]["es.uned.portal.gaia."] = ""
                thread.javas[counter]["===>"] = ""
                sheet.add_row([
                    portlet,
                    thread.javas[counter],
                    msg,
                    thread.real_end_time[counter],
                    thread.elapsed,
                    @filedate])
                counter += 1
            end
        end
    end


end
