data = "2013-02-25 10:00:38.160 [INFO] [AJPRequestHandler-ApplicationServerThread-12] es.uned.portal.gaia.matriculapas.portlet.CambioEstadoSolicitudPortlet.renderBody===> ------------> INICIO DE EJECUCION DEL RENDER <--------------"

puts "found 1 " if data.downcase =~ /renderbody===>.*inicio/
