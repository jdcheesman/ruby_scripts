require_relative 'PLSQLProc'
require 'set'

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

def procparser(infile, outfile)
    f = File.open(infile, "r")

    times = Hash[]
    params = Hash[]
    allprocs = Hash[]
    missing = Set[]

    lastmin = -1
    linecounter = 0
    f.each_line do|line|
        linecounter += 1
        # following if will need redoing in 2020. Not too concerned :)
        if line =~ /^201[3..9]/ and line =~ /AJPRequestHandler-ApplicationServerThread-/
            lineData = line.split(' ')
            time = lineData[1].split(':')
            #09:23:15.552
            hours = stripLeadingZero(time[0]).to_i
            minutes = stripLeadingZero(time[1]).to_i
            sec_ms = time[2].split('.')
            sec = stripLeadingZero(sec_ms[0]).to_i
            ms = stripLeadingZero(sec_ms[1]).to_i

            #send something to console to show we're working
            if minutes != lastmin
                printf("[%d]\t%s\n", linecounter, lineData[1])
                lastmin = minutes
            end


            normalisedTime = (hours * 60 * 60 * 1000) + (minutes * 60 * 1000) + (sec * 1000) + ms
            line[line.index(' ')] = "\t" if line =~ / /
            line[line.index(' ')] = "\t" if line =~ / /
            line[line.index(' ')] = "\t" if line =~ / /
            line[line.index(' ')] = "\t" if line =~ / /
            line[line.index(' ')] = "\t" if line =~ / /
            line["===>"] = "" if line =~ /===>/

            slices = line.split("\t")

            key = slices[3] + "#" + slices[4]
            if (slices[5].downcase =~ /inicio procedimiento/ or slices[5] =~ /\{call/ or slices[5] =~ /\{?=call/)
                #printf("found start of key=%s\n", slices[5])
                times[key] = normalisedTime
                params[key] = slices[5]
            elsif (slices[5].downcase =~ /fin procedimiento/)
                endTime = 0
                if times[key] == nil
                    missing.add(slices[4])
                else
                    endTime = normalisedTime - times[key]
                    # note allprocs DOESN'T use thread id as part of key:
                    p = PLSQLProc.new(slices[4])
                    if allprocs[slices[4]] != nil
                        p = allprocs[slices[4]]
                    end
                    p.add_call(endTime, params[key])
                    allprocs[slices[4]] = p
                end
            end
        end
    end
    f.close

    fout = File.open(outfile, "w")
    fout.write("name\tcalls\ttotal_time\tavg_time\tworst\tworst_params\n")
    allprocs.each_key do |key|
        proc = allprocs[key]
        missing.delete?(proc.name)
        avg = proc.totaltime / proc.calls

        fout.write(proc.name)
        fout.write("\t")
        fout.write(proc.calls)
        fout.write("\t")
        fout.write(proc.totaltime)
        fout.write("\t")
        fout.write(avg)
        fout.write("\t")
        fout.write(proc.worst)
        fout.write("\t")
        fout.write(proc.params)
        fout.write("\n")
        printf("Calls: %d\tTotal: %d\tAverage: %3.5f\tID: %s\n", proc.calls, proc.totaltime, avg, proc.name)
    end
    fout.close

    if missing.empty?
        print("\nAll procedures have start and end markers.\n")
    else
        print("\nFollowing procedures are missing end marker (no time calculated):\n")
        missing.each do | key |
            printf("%s\n", key)
        end
    end
    printf("%d lines processed.\n", linecounter)
end

#Expected log format:
#2013-01-24 09:23:15.552 [INFO] [AJPRequestHandler-ApplicationServerThread-24] es.uned.portal.gaia.matriculapas.portlet.EnvioCartasPortlet.renderBody===> ***INICIO DE EJECUCION --- EnvioCartasPortlet Pas***
procparser(ARGV[0],ARGV[1])

