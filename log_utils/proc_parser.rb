require_relative 'ProcParser'


#Expected log format:
#2013-01-24 09:23:15.552 [INFO] [AJPRequestHandler-ApplicationServerThread-24] es.uned.portal.gaia.matriculapas.portlet.EnvioCartasPortlet.renderBody===> ***INICIO DE EJECUCION --- EnvioCartasPortlet Pas***
myParser = ProcParser.new()
myParser.parse(ARGV[0])
myParser.createCSV(ARGV[1])
myParser.show_missing()

