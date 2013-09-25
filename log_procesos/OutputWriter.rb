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
            "Llamadas\n(dia)",
            "Peor\n(dia) (ms)",
            "Medio\n(dia) (ms)",
            "Mejor\n(dia) (ms)",
            "Llamadas\n(sem)",
            "Peor\n(sem) (ms)",
            "Medio\n(sem) (ms)",
            "Mejor\n(sem) (ms)",
            "Cambio",
            "ID Peor Llamada",
            "Param_E Peor Llamada",
            "Param_S Peor Llamada",
            "Hora Peor Llamada",
            "Fecha"])
    end


    def add_node_data_llamadas(data, sheet)
        data.each_key do |key|
            proc = data[key]
            sheet.add_row([
                proc.name,
                proc.calls.to_i,
                proc.worst.to_i,
                proc.avg.to_f,
                proc.best.chomp.strip.to_i,
                proc.calls_wk.to_i,
                proc.worst_wk.to_i,
                proc.avg_wk.to_f,
                proc.best_wk.to_i,
                proc.percent_change.gsub(/\./, ',').chomp.strip,
                proc.id_worst,
                proc.plSqlData_worst_E,
                proc.plSqlData_worst_S,
                proc.worst_time,
                @filedate
                ])
        end
    end

end
