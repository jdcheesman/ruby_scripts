require_relative 'ProcParser'
require_relative 'PLSQLProc'
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

printf("cleanedup:[%s]\n", cleanedup)




data = "{?=call UNED.fcursoacad()}()"
printf("Matching: %s\n", data)
res = PLSQLProc.get_proc_name(data)
printf("Res: %s\n\n", res)


data = " {call MATRICULAS.PK_REC_MATRICULAS.Obtener_cartas_procesoacad(?,?)}(MP) ***"
printf("Matching: %s\n", data)
res = PLSQLProc.get_proc_name(data)
printf("Res: %s\n\n", res)

data = "AnADIR DOMICILIO CON TIPO USUARIO{call MATRICULAS.PK_AC_DATPER_DOMICILIOS.insertar_domicilio(?,?,?,?,?,?,?,?,?,?,?,?)}(F02 )"
printf("Matching: %s\n", data)
res = PLSQLProc.get_proc_name(data)
printf("Res: %s\n\n", res)


data = " UNED.PK_LISTGENERALES.dirapc_fac(03, 10)"
printf("Matching: %s\n", data)
res = PLSQLProc.get_proc_name(data)
printf("Res: %s\n\n", res)



data = "es.uned.portal.gaia.core.bd.sql.UsuarioAutenticadoDao.permisoEntidades===>#POSGRADO_PRO.PK_ACCESOS.permiso_entidades_mat"
slicedJava = /([a-zA-Z\.]+)\.([a-zA-Z_]+)\W*?#.+/.match(data)
printf("1: %s\n\n", slicedJava[1])
printf("2: %s\n\n", slicedJava[2])

data = "es.uned.portal.gaia.certificadospas.bd.sql.CertificadosDao.obtenerAsignaturas#POSGRADO_PRO.PK_REC_CERTIFICADOS.obtener_asignaturas"
slicedJava = /([a-zA-Z\.]+)\.([a-zA-Z_]+)\W*?#.+/.match(data)
printf("1: %s\n\n", slicedJava[1])
printf("2: %s\n\n", slicedJava[2])


data = "09:23:15.552"
printf("Hour_minute: %s\n", ProcParser.get_hour_minute(data))
data = "09:03:15.552"
printf("Hour_minute: %s\n", ProcParser.get_hour_minute(data))
data = "10:23:15.552"
printf("Hour_minute: %s\n", ProcParser.get_hour_minute(data))
data = "00:00:15.552"
printf("Hour_minute: %s\n", ProcParser.get_hour_minute(data))



 # SimpleXlsx::Serializer.new("test.xlsx") do |doc|
 #    doc.add_sheet("People") do |sheet|
 #      sheet.add_row(%w{DoB Name Occupation})
 #      sheet.add_row(["31-07-1912",
 #                     "Milton Friedman",
 #                     "Economist / Statistician"])
 #    end
 #  end

