class MyProc
    attr_accessor   :name
    attr_accessor   :worst
    attr_accessor   :best
    attr_accessor   :plSqlData_worst
    attr_accessor   :plSqlData_best
    attr_accessor   :worst_time
    attr_accessor   :best_time
    attr_accessor   :totaltime
    attr_accessor   :calls

    def initialize(name)
        @name = name.chomp.strip
        @worst = 0
        @best = 1000000
        @totaltime = 0
        @calls = 0
    end

    def add_call(elapsed, callplSqlData, time)
        if elapsed > @worst
            @plSqlData_worst = callplSqlData
            @worst = elapsed
            @worst_time = time
            printf("New worst [%s] [%d]\n", @name, elapsed)
        end
        if elapsed < @best
            @plSqlData_best = callplSqlData
            @best = elapsed
            @best_time = time
        end

        @calls = @calls + 1
        @totaltime = @totaltime + elapsed
    end

    def to_json
        "{\"name\":\"" + @name + "\",\n" +
            "\t\"worst\":{\"worst_duration\":\"" + @worst.to_s + "\", \"plSqlData_worst\":\"" + @plSqlData_worst.to_s + "\", \"worst_time\": \"" + @worst_time.to_s + "\"},\n" +
            "\t\"best\":{\"best_duration\":\"" + @best.to_s + "\", \"plSqlData_best\":\"" + @plSqlData_best.to_s + "\", \"best_time\":\"" + @best_time.to_s + "\"},\n" +
            "\t\"totals\":{\"totaltime\":\"" + @totaltime.to_s + "\",\"calls\":\"" + @calls.to_s + "\",\"avg\":\"" + (@totaltime / @calls).to_s + "\"}\n" +
        "}"
    end
end
