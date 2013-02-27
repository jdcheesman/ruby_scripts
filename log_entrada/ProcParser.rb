require_relative 'Error'

class ProcParser

    attr :filename
    attr_accessor :errors

    def initialize(filename)
        @filename = filename
        @errors = Hash[]
    end

    def parse()
        f = File.open(@filename, "r")
        f.each_line do|line|
            line_data = line.split('$')
            line_data[2]["Error -->"] = line_data[2][""] if line_data[2] =~ /Error -->/

            matched = parse_line_with_id("Instancia: orc5. Mensaje: (.+)\. Entrada --> p_identificador: ([a-zA-Z_ 0-9]+)\. (.+)", line_data[2], line_data[0])
            # puts "found 0" if matched
#Instancia: orc5. Mensaje: Error en SOID_CAMBIO_CLAVE.CAMBIOPASSWORDPORID al llamar a SOID_LDAP.ACTUALIZAPASSWORD. Entrada --> p_identificador: aruiz1016
            if (!matched)
               matched = parse_line_actualiza_password("Instancia: orc5. Mensaje: Error en SOID_CAMBIO_CLAVE.CAMBIOPASSWORDPORID (.+)\. Entrada --> p_identificador: (.+)", line_data[2], line_data[0])
               # puts "found 4" if matched
            end

#Instancia: orc5. Mensaje: Error en SOID_LDAP.ActualizaPassword al hacer el update en tabla usuarios_oid de la fecha y cenModif. Entrada --> p_identificador: etorrecil8

            if (!matched)
               matched = parse_line_actualiza_password("Instancia: orc5. Mensaje: Error en SOID_LDAP.ActualizaPassword (.+)\. Entrada --> p_identificador: (.+)", line_data[2], line_data[0])
               # puts "found 4" if matched
            end
#Instancia: orc5. Mensaje: Error en SOID_LDAP.InsertarUsuarioLDAP al llamar a InsertarUsuarioLDAP_OpenLDAP. Entrada --> p_dni: 25151177
            if (!matched)
               matched = parse_line_actualiza_password("Instancia: orc5. Mensaje: Error en SOID_LDAP.InsertarUsuarioLDAP (.+)\. Entrada --> p_dni: (.+)", line_data[2], line_data[0])
               # puts "found 4" if matched
            end
            if (!matched)
#Instancia: orc5. Mensaje: Error en SOID.GrabarConsultaMAPDatPer al llamar a MATRICULAS.MODIFGEN_DATPER. Entrada -> p_dni: 33529896. p_consulta: S .Salida -> ps_salida: -4098. ps_mensaje: ORA-04098: el disparador 'MATRICULAS.DATPER_LDAP' no es válido y ha fallado al revalidar
#Instancia: orc5. Mensaje: Error Oracle en SOID_CAMBIO_CLAVE.CAMBIOPASSWORDPORID. Entrada --> p_identificador: afernande2328. Error --> SqlCode: -6508 SqlErrm: ORA-06508: PL/SQL: no se ha encontrado la unidad de programa llamada
                matched = parse_line_with_id("Instancia: orc5. Mensaje: (.+)\. Entrada -> p_dni: ([a-zA-Z_ 0-9]+)\. p_consulta: [SN] \.Salida -> (.+)", line_data[2], line_data[0])
                # puts "found 1" if matched
            end

#Instancia: orc5. Mensaje: Error Oracle en SOID_LDAP.InsertarUsuarioLDAP. Entrada --> p_dni: 8990610. Error --> SqlCode: -6508 SqlErrm: ORA-06508: PL/SQL: no se ha encontrado la unidad de programa llamada
            if (!matched)
                matched = parse_line_with_id("Instancia: orc5. Mensaje: (.+)\. Entrada --> p_dni: ([a-zA-Z_ 0-9]+)\. (.+)", line_data[2], line_data[0])
                # puts "found 2" if matched
            end
#Instancia: orc5. Mensaje: Error Oracle en SOID_CAMBIO_CLAVE.ObtenerIdPorToken. Entrada --> 4f459c:12acbd5d1c8:-7ecf. Error --> SqlCode: 100 SqlErrm: ORA-01403: no se han encontrado datos
            if (!matched)
                matched = parse_line_with_id("Instancia: orc5. Mensaje: (.+)\. Entrada --> ([a-zA-Z_ 0-9:-]+)\. (.+)", line_data[2], line_data[0])
                # puts "found 3" if matched
            end



            # all others:
            if (!matched)
               matched = parse_line("Instancia: orc5. Mensaje: (.+)\. SqlCode(.+)", line_data[2])
               # puts "found LAST chance saloon" if matched
            end

            if (!matched)
                printf("Not matched: %s\n", line_data)
            end
        end
    end


    def get_key(data)
        data = data.chomp + " "
        if data =~ /.+(SOID[a-zA-Z_0-9]*)\.([a-zA-Z_]+)[\.]* .*/
            m = /.+(SOID[a-zA-Z_0-9]*)\.([a-zA-Z_]+)[\.]* .*/.match(data)
            m[1] + "." + m[2]
        else
            printf("No match for: [%s]\n", data)
            "unknown key"
        end
    end

#Instancia: orc5. Mensaje: Error Oracle en SOID_CAMBIO_CLAVE.ObtenerIdPorToken. SqlCode: 100 SqlErrm: ORA-01403: no se han encontrado datos
    def parse_line(pattern, line)
        if line =~ /#{pattern}/
            m = /#{pattern}/.match(line)
            key = get_key(line)
            if @errors[key] == nil
                @errors[key] = Error.new(key)
            end
            @errors[key].add_msg("SqlCode" + m[2])
            true
        else
            false
        end
    end

    def parse_line_actualiza_password(pattern, line, date)
        if line =~ /#{pattern}/
            m = /#{pattern}/.match(line)
            key = get_key(line)
            if @errors[key] == nil
                @errors[key] = Error.new(key)
            end
            @errors[key].add_user(m[2], date.split(' ')[0] + "$" + date.split(' ')[1] + "$" + line)
            @errors[key].add_msg(m[1])
            true
        else
            false
        end
    end

#Instancia: orc5. Mensaje: Error Oracle en SOID_CAMBIO_CLAVE.CAMBIOPASSWORDPORID. Entrada --> p_identificador: fbaladan1. Error --> SqlCode: -2399 SqlErrm: ORA-02399: ha excedido el tiempo máximo de conexión, desconectando
    def parse_line_with_id(pattern, line, date)
        if line =~ /#{pattern}/
            m = /#{pattern}/.match(line)
            key = get_key(line)
            if @errors[key] == nil
                @errors[key] = Error.new(key)
            end
            @errors[key].add_user(m[2], date.split(' ')[0] + "$" + date.split(' ')[1] + "$" + line)
            @errors[key].add_msg(m[3])
            true
        else
            false
        end
    end


end