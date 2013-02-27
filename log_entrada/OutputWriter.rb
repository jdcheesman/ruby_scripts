require 'rubygems'
require 'simple_xlsx'


class OutputWriter

    attr :filename

    def initialize(filename)
        @filename = filename
    end

    def write_xlsx(errordata)
        SimpleXlsx::Serializer.new(@filename) do |doc|
            doc.add_sheet("ERRORES") do |sheet|
                set_titles_errores(sheet)
                add_node_data_errores(errordata, sheet)
            end
            doc.add_sheet("IDENTIFICADORES") do |sheet|
                set_titles_identifiers(sheet)
                add_node_data_identifiers(errordata, sheet)
            end
        end
    end


    def set_titles_errores(sheet)
        sheet.add_row([
            "Fuente",
            "Mensaje",
            "Recuento"
            ])
    end

    def add_node_data_errores(data, sheet)
        data.each_key do |key|
            error = data[key]
            error.msg.each_key do | msg_id |
                num = error.msg[msg_id]
                sheet.add_row([
                    key,
                    msg_id,
                    num
                    ])
            end
        end
    end



    def set_titles_identifiers(sheet)
        sheet.add_row(["Fecha",
            "Hora",
            "ID",
            "Operacion",
            "Linea completa"
            ])
    end

    def add_node_data_identifiers(data, sheet)
        data.each_key do |key|
            error = data[key]
            error.usr.each_key do | usr_id |
                all_data = error.usr[usr_id].split('$')
                date = all_data[0]
                if date !~ /201[01]$/
                    time = all_data[1]
                    line = all_data[2]
                    sheet.add_row([
                        date,
                        time,
                        usr_id,
                        key,
                        line
                    ])
                end
            end
        end
    end

end
