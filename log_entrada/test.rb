require_relative 'ProcParser.rb'


def test_this(data)
    myParser = ProcParser.new("nothing")
    printf("\nTesting: [%s]\n", data)
    printf("Res: %s\n", myParser.get_key(data))
end




data = "Error Oracle en SOID_CAMBIO_CLAVE.ObtenerIdPorToken "
test_this(data)

data = "Error Oracle en SOID_CAMBIO_CLAVE.CAMBIOPASSWORDPORID "
test_this(data)

data = "Error en SOID.GrabarConsultaMAPDatPer al llamar a MATRICULAS.MODIFGEN_DATPER "
test_this(data)

data = "Instancia: orc5. Mensaje: Error en SOID_LDAP.InsertarUsuarioLDAP al llamar a InsertarUsuarioLDAP_OpenLDAP. Entrada --> p_dni: 25151177"
test_this(data)

data = "Instancia: orc5. Mensaje: Error Oracle en SOID_CAMBIO_CLAVE.ObtenerIdPorToken. Entrada --> 633e5e:12ad622752f:-7efc.  SqlCode: 100 SqlErrm: ORA-01403: no se han encontrado datos "
test_this(data)

data = "Instancia: orc5. Mensaje: Error Oracle en SOID_CAMBIO_CLAVE2.ObtenerIdPorToken. SqlCode: 100 SqlErrm: ORA-01403: no se han encontrado datos"
test_this(data)

date = "20/12/11"
split_date = date.split('/')
new_date = "%s/%s/20%s" % [split_date[0], split_date[1], split_date[2]]
printf("new date: %s\n", new_date)