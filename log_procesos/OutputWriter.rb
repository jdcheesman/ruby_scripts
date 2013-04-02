require 'rubygems'
require 'simple_xlsx'


class OutputWriter

    attr :filename
    attr :filedate

    def initialize(filename, filedate)
        @filename = filename
        @filedate = filedate
        @worst_thread = Hash[]
    end

    def write_xlsx(alldata)
        SimpleXlsx::Serializer.new(@filename) do |doc|
            doc.add_sheet("DATOS") do |sheet|
                set_titles_llamadas(sheet)
                add_node_data_llamadas(alldata, sheet)
            end

        end
    end

    def set_titles_llamadas(sheet)
        sheet.add_row([
            "Nombre proc",
            "Num Llamadas",
            "Total (ms)",
            "Medio (ms)",
            "Peor (ms)",
            "Mejor (ms)",
            "ID Peor Llamada",
            "Param_E Peor Llamada",
            "Param_S Peor Llamada",
            "Hora Peor Llamada",
            "ID Mejor Llamada",
            "Param_E Mejor Llamada",
            "Param_S Mejor Llamada",
            "Hora Mejor Llamada",
            "Fecha"])
    end


    def add_node_data_llamadas(data, sheet)
        data.each_key do |key|
            proc = data[key]
            avg = (proc.totaltime*1.0) / (proc.calls*1.0)
            if proc.plSqlData_worst != nil
                data_worst = proc.plSqlData_worst.split('#')
            else
                data_worst = Array[]
            end
            if proc.plSqlData_best != nil
                data_best = proc.plSqlData_best.split('#')
            else
                data_best = Array[]
            end
            sheet.add_row([
                proc.name,
                proc.calls,
                proc.totaltime,
                avg,
                proc.worst,
                proc.best,
                data_worst[0],
                data_worst[1],
                data_worst[2],
                proc.worst_time,
                data_best[0],
                data_best[1],
                data_best[2],
                proc.best_time,
                @filedate
                ])
        end
    end

end
