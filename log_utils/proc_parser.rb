require_relative 'ProcParser'
require_relative 'OutputWriter'

def getfilename(root)
    time = Time.new
    root["\\"] = "" if root =~ /\\/
    "log_" + root + "_" + time.year.to_s + time.month.to_s + time.day.to_s + "-" +  time.hour.to_s + time.min.to_s + ".xlsx"
end

#Expected log format:
#2013-01-24 09:23:15.552 [INFO] [AJPRequestHandler-ApplicationServerThread-24] es.uned.portal.gaia.matriculapas.portlet.EnvioCartasPortlet.renderBody===> ***INICIO DE EJECUCION --- EnvioCartasPortlet Pas***

alldata = Hash[]
errordata = Hash[]
calldata = Hash[]
missingdata = Hash[]

filedate = "START"

Dir.foreach(ARGV[0]) do |f|

    if f =~ /\.log$/
        printf("Processing: %s\n", f)
        myParser = ProcParser.new(ARGV[0], f)
        numLines = myParser.parse()
        printf("\t%d lines processed.\n", numLines)
        errorRate = (myParser.errorcount*1.0) / (numLines*1.0)
        printf("\t%d errors found, rate=%1.5f.\n", myParser.errorcount, errorRate)
        alldata[myParser.nodename] = myParser.allprocs
        errordata[myParser.nodename] = myParser.errors
        calldata[myParser.nodename] = myParser.calls
        missingdata[myParser.nodename] = myParser.missing
        if !(filedate == "START") & !(filedate == myParser.date)
            printf("Log files spans various dates (only last date used in ouput): %s != %s\n", filedate, myParser.date)
        end
        filedate =myParser.date
    end

end

outputfilename = getfilename(ARGV[0])
outputWriter = OutputWriter.new(outputfilename, filedate)
outputWriter.write_xlsx(alldata, errordata, calldata, missingdata)

printf("Result file:\n%s\n", outputfilename)