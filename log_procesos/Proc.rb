class MyProc
    attr_accessor   :name
    attr_accessor   :worst
    attr_accessor   :best
    attr_accessor   :avg
    attr_accessor   :id_worst
    attr_accessor   :plSqlData_worst_E
    attr_accessor   :plSqlData_worst_S
    attr_accessor   :worst_time
    attr_accessor   :calls

    attr_accessor :worst_wk
    attr_accessor :best_wk
    attr_accessor :avg_wk
    attr_accessor :calls_wk
    attr_accessor :percent_change

    def initialize(name, worst, avg, best, calls)
        @name = name.chomp.strip
        @worst = worst
        @avg = avg
        @best = best
        @calls = calls
    end

     def clean_time(time)
        #"2013-04-12 00:10:17 +0200"
        time_split = time.split(' ');
        time_split[0] + ' ' + time_split[1]
    end

    def add_worst_data(id_worst, callplSqlData_E, callplSqlData_S, time)
        @id_worst = id_worst
        @plSqlData_worst_E = callplSqlData_E
        @plSqlData_worst_S = callplSqlData_S
        @worst_time = clean_time(time)
    end


    def to_json
        "{\"name\":\"" + @name + "\",\n" +
            "\t\"worst\":{\"worst_duration\":\"" + @worst.to_s.chomp.strip + "\", \"plSqlData_worst\":\"" + @plSqlData_worst.to_s.chomp.strip + "\", \"worst_time\": \"" + @worst_time.to_s.chomp.strip + "\"},\n" +
            "\t\"best\":{\"best_duration\":\"" + @best.to_s.chomp.strip + "\"},\n" +
            "\t\"totals\":{\"totaltime\":\"" + @totaltime.to_s.chomp.strip + "\",\"calls\":\"" + @calls.to_s.chomp.strip + "\",\"avg\":\"" + avg.to_s.chomp.strip + "\"}\n" +
            "\t\"week\":{\"worst_wk\":\"" + @worst_wk.to_s.chomp.strip + "\",\"calls_wk\":\"" + @calls_wk.to_s.chomp.strip + "\",\"avg_wk\":\"" + @avg_wk.to_s.chomp.strip + "\",\"best_wk\":\"" + @best_wk.to_s.chomp.strip + "\",\"percent_change\":\"" + @percent_change.to_s.chomp.strip + "\"}\n" +
        "}"
    end
end
