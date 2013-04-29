f = File.open(ARGV[0], "r")


f_out = File.open(ARGV[1], "w")

line_counter = 0
current_module = ""
current_header = ""

f.each_line do|line|
        if line =~ /^[ ]+CPU/ or line =~ /^[ ]+% Total/ or line =~ /------/
            # puts line
        else
            line = line.chomp.strip
            line_counter += 1
            if line == "Buffer Gets    Executions  Gets per Exec  %Total Time (s)  Time (s) Hash Value" and line != current_header
                current_header = line
                f_out.write("Buffer Gets#Executions#Gets per Exec#%Total#CPU Time (s)#Elapsed Time (s)#Hash Value#Txt#Module")
            elsif line == "Physical Reads  Executions  Reads per Exec %Total Time (s)  Time (s) Hash Value" and line != current_header
                current_header = line
                f_out.write("\n\nPhysical Reads#Executions#Reads per Exec#%Total#CPU Time (s)#Elapsed Time (s)#Hash Value#Txt#Module")
            elsif line == "Executions   Rows Processed   Rows per Exec    Exec (s)   Exec (s)  Hash Value" and line != current_header
                current_header = line
                f_out.write("\n\nExecutions#Rows Processed#Rows per Exec#CPU per Exec (s)#Elap per Exec (s)#Hash Value#Txt#Module")
            elsif line == "Parse Calls  Executions   Parses  Hash Value" and line != current_header
                current_header = line
                f_out.write("\n\nParse Calls#Executions#% Total Parses#Hash Value#Txt#Module")
            elsif line == "Sharable Mem (b)  Executions  % Total  Hash Value" and line != current_header
                current_header = line
                f_out.write("\n\nSharable Mem (b)#Executions#% Total#Hash Value#Txt#Module")
            elsif line == "Count  Executions   Hash Value" and line != current_header
                current_header = line
                f_out.write("\n\nVersion Count#Executions#Hash Value#Txt#Module")

            # 379,712,947        6,694       56,724.4   10.7  1802.81   8425.40  702041218
            elsif line =~ /^([0-9,\.]+)[ ]+([0-9,\.]+)[ ]+([0-9,\.]+)[ ]+([0-9,\.]+)[ ]+([0-9,\.]+)[ ]+([0-9,\.]+)[ ]+([0-9,\.]+)$/
                puts line
                    if line_counter != 1
                        f_out.write("#")
                        f_out.write(current_module)
                        f_out.write("\n")
                    end
                    data = /^([0-9,\.]+)[ ]+([0-9,\.]+)[ ]+([0-9,\.]+)[ ]+([0-9,\.]+)[ ]+([0-9,\.]+)[ ]+([0-9,\.]+)[ ]+([0-9,\.]+)$/.match(line)
                    [1,2,3,4,5,6,7].each do |i|
                        data_to_write = data[i].gsub(',', '').gsub('.',',')
                        f_out.write(data_to_write)
                        f_out.write("#")
                    end

            # line 272
            # 77,460,015      14,733,188              0.2       0.00        0.00 1743952982
            elsif line =~ /^([0-9,\.]+)[ ]+([0-9,\.]+)[ ]+([0-9,\.]+)[ ]+([0-9,\.]+)[ ]+([0-9,\.]+)[ ]+([0-9,\.]+)$/
                puts line
                    if line_counter != 1
                        f_out.write("\n")
                    end
                    data = /^([0-9,\.]+)[ ]+([0-9,\.]+)[ ]+([0-9,\.]+)[ ]+([0-9,\.]+)[ ]+([0-9,\.]+)[ ]+([0-9,\.]+)$/.match(line)
                    [1,2,3,4,5,6].each do |i|
                        data_to_write = data[i].gsub(',', '').gsub('.',',')
                        f_out.write(data_to_write)
                        f_out.write("#")
                    end

            # line 426
            # 1,807,755    1,807,754    32.72 1393666712
            elsif line =~ /^([0-9,\.]+)[ ]+([0-9,\.]+)[ ]+([0-9,\.]+)[ ]+([0-9,\.]+)$/
                    puts line
                    if line_counter != 1
                        f_out.write("\"\n")
                    end
                    data = /^([0-9,\.]+)[ ]+([0-9,\.]+)[ ]+([0-9,\.]+)[ ]+([0-9,\.]+)$/.match(line)
                    [1,2,3,4].each do |i|
                        data_to_write = data[i].gsub(',', '').gsub('.',',')
                        f_out.write(data_to_write)
                        f_out.write("#")
                    end
            elsif line =~ /^([0-9,\.]+)[ ]+([0-9,\.]+)[ ]+([0-9,\.]+)$/
                    puts line
                    if line_counter != 1
                        f_out.write("\"\n")
                    end
                    data = /^([0-9,\.]+)[ ]+([0-9,\.]+)[ ]+([0-9,\.]+)$/.match(line)
                    [1,2,3].each do |i|
                        data_to_write = data[i].gsub(',', '').gsub('.',',')
                        f_out.write(data_to_write)
                        f_out.write("#")
                    end
            elsif line =~ /Module: (.+)/
                    data = /Module: (.+)/.match(line)
                    current_module = data[1]
            else
                f_out.write(line)
                f_out.write(" ")
            end
        end

end

f.close
f_out.close