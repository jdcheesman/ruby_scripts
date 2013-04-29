require_relative 'ProcParser'
require_relative 'OutputWriter'

=begin

Aplicacion para parsear el log de errores de alta de usuarios.

Hay que pasar el data_munger primero para limpiar el log.

=end


def getfilename()
    time = Time.new
    "log_" + time.year.to_s + time.month.to_s + time.day.to_s + "-" +  time.hour.to_s + time.min.to_s + ".xlsx"
end

myParser = ProcParser.new(ARGV[0])
myParser.parse()


outputfilename = getfilename()
outputWriter = OutputWriter.new(outputfilename)
outputWriter.write_xlsx(myParser.errors)

printf("Output file: %s\n", outputfilename)