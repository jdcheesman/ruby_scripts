TIME_SLICE = 1
line = "2013-01-24 09:03:05.002 [INFO] [AJPRequestHandler-ApplicationServerThread-24] es.uned.portal.gaia.matriculapas.portlet.EnvioCartasPortlet.renderBody===> ***INICIO DE EJECUCION --- EnvioCartasPortlet Pas***"
lineData = line.split(' ', 6)
m = /[0]?(\d+):[0]?(\d+):[0]?(\d+)\.[0]?[0]?(\d+)/.match(lineData[TIME_SLICE])

printf("0: %s\n", m[0])
printf("1: %s\n", m[1])
printf("2: %s\n", m[2])
printf("3: %s\n", m[3])
printf("4: %s\n", m[4])



data = "es.uned.portal.gaia.core.bd.sql.AlumnoDao.obtenerDatosAcademicos"

z = /([a-zA-Z\.]+)\.([a-zA-Z]+)/.match(data)
printf("0: %s\n", z[0])
printf("1: %s\n", z[1])
printf("1: %s\n", z[2])

