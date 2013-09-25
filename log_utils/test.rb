# data = "2013-02-25 10:00:38.160 [INFO] [AJPRequestHandler-ApplicationServerThread-12] es.uned.portal.gaia.matriculapas.portlet.CambioEstadoSolicitudPortlet.renderBody===> ------------> INICIO DE EJECUCION DEL RENDER <--------------"

# puts "found 1 " if data.downcase =~ /renderbody===>.*inicio/


description = "ORA-20290 No se han podido almacenar correctamente los datos introducidos 123."
slicedCode = /^(ORA\-[0-9]+) ([\w\W]+)$/.match(description)

puts slicedCode[1]
puts slicedCode[2]