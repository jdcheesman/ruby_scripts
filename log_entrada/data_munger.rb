

f = File.open(ARGV[0], "r")
fout = File.open(ARGV[1], "w")
previous_line = ""
f.each_line do|line|
    line = line.chomp
    if previous_line != ""
        if line =~ /^ORA-[0-9]+:/
            printf("Found: %s\n", line)
            previous_line = previous_line + " " + line
        else
            fout.write(previous_line)
            fout.write("\n")
            previous_line = line
        end
    else
        previous_line = line
    end
end
fout.write(previous_line)
fout.write("\n")
f.close
fout.close