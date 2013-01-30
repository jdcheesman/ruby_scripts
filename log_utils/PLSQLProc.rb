class PLSQLProc
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
        @name["===>"] = "" if @name =~ /===>/
        @worst = 0
        @best = 1000000
        @totaltime = 0
        @calls = 0
    end

    def add_call(elapsed, callplSqlData, time)
        if elapsed > @worst
            @plSqlData_worst = clean_up_plSqlData(callplSqlData)
            @worst = elapsed
            @worst_time = time
        end
        if elapsed < @best
            @plSqlData_best = clean_up_plSqlData(callplSqlData)
            @best = elapsed
            @best_time = time
        end

        @calls = @calls + 1
        @totaltime = @totaltime + elapsed
    end

private

    def clean_up_plSqlData(pp)
        localpp = pp.chomp.strip
        localpp = clean(localpp, "---> INICIO PROCEDIMIENTO:")
        localpp = clean(localpp, "*** Inicio Procedimiento -->")
        localpp = clean(localpp, "*** INICIO PROCEDIMIENTO:  -->")
        localpp = clean(localpp, "INICIO PROCEDIMIENTO -")
        localpp = clean(localpp, "--->INICIO PROCEDIMIENTO:")
        localpp = clean(localpp, "---> INICIO PROCEDIMIENTO ")
        localpp = clean(localpp, "Proceso:")
        localpp = clean(localpp, "prepararProc->")
        localpp = clean(localpp, "prepararProc--->")
        localpp
    end

    def clean(text, pattern)
        text[pattern] = "" if text =~ /^#{Regexp.escape(pattern)}/
        text
    end

end
