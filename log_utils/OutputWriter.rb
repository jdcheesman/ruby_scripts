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


    def initialize(filename)
        @filename = filename
    end

    def write_xlsx(alldata, errordata)
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
            "Hora Mejor Llamada"])
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
                proc.best_time
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
            "Descripcion"])
    end

    def add_node_data_errores(nodename, data, sheet)
        data.each do |log_error|
            sheet.add_row([
                nodename,
                log_error.time,
                log_error.java_class,
                log_error.java_method,
                log_error.code,
                log_error.description
                ])
        end
    end
end
