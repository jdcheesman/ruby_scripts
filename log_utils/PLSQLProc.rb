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
            @plSqlData_worst = PLSQLProc.clean_up_plSqlData(callplSqlData)
            @worst = elapsed
            @worst_time = time
        end
        if elapsed < @best
            @plSqlData_best = PLSQLProc.clean_up_plSqlData(callplSqlData)
            @best = elapsed
            @best_time = time
        end

        @calls = @calls + 1
        @totaltime = @totaltime + elapsed
    end




    def self.get_proc_name(plSqlData_worst)
        if plSqlData_worst =~ /call /
            m = /call ([a-zA-Z\._]+)\(*+/.match(plSqlData_worst)
            m[1]
        elsif plSqlData_worst =~ /\(/
            m = /([a-zA-Z\._ ]+)\(*+/.match(plSqlData_worst)
            m[1]
        else
            plSqlData_worst
        end
    end

    def self.clean_up_plSqlData(pp)
        localpp = pp.chomp.strip
        localpp = clean(localpp, "---> INICIO PROCEDIMIENTO: *** INICIO PROCEDIMIENTO - ")
        localpp = clean(localpp, "---> INICIO PROCEDIMIENTO:")
        localpp = clean(localpp, "*** Inicio Procedimiento -->")
        localpp = clean(localpp, "*** INICIO PROCEDIMIENTO:  -->")
        localpp = clean(localpp, "INICIO PROCEDIMIENTO -")
        localpp = clean(localpp, "--->INICIO PROCEDIMIENTO:")
        localpp = clean(localpp, "---> INICIO PROCEDIMIENTO ")
        localpp = clean(localpp, "*** INICIO PROCEDIMIENTO - ")
        localpp = clean(localpp, "*** Inicio Procedimietnos -->")
        localpp = clean(localpp, "Proceso:")
        localpp = clean(localpp, "prepararProc->")
        localpp = clean(localpp, "prepararProc--->")
        localpp
    end

private

    def self.clean(text, pattern)
        text[pattern] = "" if text =~ /^#{Regexp.escape(pattern)}/
        text
    end

end
