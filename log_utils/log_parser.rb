def stripLeadingZero(num)
    if num.length == 3
        if num[0] == '0'
            num[0] = ''
        end
    end
    if num[0] == '0'
        num = num[1]
    end
    num
end

def logparser(infile, outfile, includesThread)
    f = File.open(infile, "r")
    fout = File.open(outfile, "w")

#2013-01-24 09:23:15.552 [INFO] [AJPRequestHandler-ApplicationServerThread-24] es.uned.portal.gaia.matriculapas.portlet.EnvioCartasPortlet.renderBody===> ***INICIO DE EJECUCION --- EnvioCartasPortlet Pas***


    lastLine = ""
    lastTime = -1

    if includesThread
        fout.write("elapsed\tdate\ttime\tlevel\tthread\tmsg\tparam")
    else
        fout.write("elapsed\tdate\ttime\tlevel\tmsg\tparam")
    end

    f.each_line do|line|

        if line =~ /^2013/

            time = line.split(' ')[1].split(':')
            #09:23:15.552
            hours = stripLeadingZero(time[0]).to_i
            min = stripLeadingZero(time[1]).to_i
            seg_ms = time[2].split('.')
            seg = stripLeadingZero(seg_ms[0]).to_i
            ms = stripLeadingZero(seg_ms[1]).to_i

            normalisedTime = (hours * 60 * 60 * 1000) + (min * 60 * 1000) + (seg * 1000) + ms
            line[line.index(' ')] = "\t"
            line[line.index(' ')] = "\t"
            line[line.index(' ')] = "\t"
            line[line.index(' ')] = "\t"
            line["===>"] = ""
            if includesThread
                line[line.index(' ')] = "\t"
            end


            if lastTime != -1
                elapsedTime = normalisedTime-lastTime
                fout.write( elapsedTime )
                fout.write( "\t" + lastLine)
            end
            lastTime = normalisedTime
            lastLine = line
        end
    end
    fout.write( "0\t" + lastLine)

    f.close
    fout.close

end

if ARGV[0] == "-nothread"
    logparser(ARGV[1],ARGV[2], false)
else
    logparser(ARGV[0],ARGV[1], true)
end
