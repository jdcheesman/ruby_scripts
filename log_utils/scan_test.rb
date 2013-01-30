require 'rubygems'
require 'simple_xlsx'


    def clean_up_plSqlData(pp)
        localpp = pp.chomp.strip
        localpp = clean(localpp, "---> INICIO PROCEDIMIENTO:")
        localpp = clean(localpp, "*** Inicio Procedimiento -->")
        localpp = clean(localpp, "*** INICIO PROCEDIMIENTO:  -->")
        localpp = clean(localpp, "INICIO PROCEDIMIENTO -")
        localpp = clean(localpp, "--->INICIO PROCEDIMIENTO:")
        localpp = clean(localpp, "---> INICIO PROCEDIMIENTO ")
        localpp = clean(localpp, "Proceso:")
        localpp = clean(localpp, "prepararProc->")
        localpp = clean(localpp, "prepararProc--->")
        localpp
    end

    def clean(text, pattern)
        text[pattern] = "" if text =~ /^#{Regexp.escape(pattern)}/
        text
    end

TIME_SLICE = 1
PLSQL_SLICE = 5




#line = "2013-01-24 09:03:05.002 [INFO] [AJPRequestHandler-ApplicationServerThread-24] es.uned.portal.gaia.matriculapas.portlet.EnvioCartasPortlet.renderBody===> ***INICIO DE EJECUCION --- EnvioCartasPortlet Pas***"
line = "2013-01-24 09:23:15.562 [INFO] [AJPRequestHandler-ApplicationServerThread-24] es.uned.portal.gaia.core.bd.sql.UsuarioAutenticadoDao.cursoAcademico===> ---> INICIO PROCEDIMIENTO: {?=call UNED.fcursoacad()}()"
lineData = line.split(' ', 6)

printf("PRE:[%s]\n", lineData[PLSQL_SLICE])

cleanedup = clean_up_plSqlData(lineData[PLSQL_SLICE])

print cleanedup


# m = /[0]?(\d+):[0]?(\d+):[0]?(\d+)\.[0]?[0]?(\d+)/.match(lineData[TIME_SLICE])

# printf("0: %s\n", m[0])
# printf("1: %s\n", m[1])
# printf("2: %s\n", m[2])
# printf("3: %s\n", m[3])
# printf("4: %s\n", m[4])



# data = "es.uned.portal.gaia.core.bd.sql.AlumnoDao.obtenerDatosAcademicos"

# z = /([a-zA-Z\.]+)\.([a-zA-Z]+)/.match(data)
# printf("0: %s\n", z[0])
# printf("1: %s\n", z[1])
# printf("1: %s\n", z[2])


 SimpleXlsx::Serializer.new("test.xlsx") do |doc|
    doc.add_sheet("People") do |sheet|
      sheet.add_row(%w{DoB Name Occupation})
      sheet.add_row(["31-07-1912",
                     "Milton Friedman",
                     "Economist / Statistician"])
    end
  end

