class PLSQLProc
    attr_accessor   :name
    attr_accessor   :worst
    attr_accessor   :plSqlData
    attr_accessor   :totaltime
    attr_accessor   :calls

    def initialize(name)
        @name = name.chomp.strip
        @name["===>"] = "" if @name =~ /===>/
        @worst = 0
        @totaltime = 0
        @calls = 0
    end

    def add_call(elapsed, callplSqlData)
        if elapsed > @worst
            @plSqlData = clean_up_plSqlData(callplSqlData)
            @worst = elapsed
        end
        @calls = @calls + 1
        @totaltime = @totaltime + elapsed
    end

    def clean_up_plSqlData(pp)
        localpp = pp.chomp.strip
        localpp["---> INICIO PROCEDIMIENTO:"] = ""      if localpp =~ /^---> INICIO PROCEDIMIENTO:/
        localpp["*** Inicio Procedimiento -->"] = ""    if localpp =~ /^*** Inicio Procedimiento -->/
        localpp["*** INICIO PROCEDIMIENTO:  -->"] = ""  if localpp =~ /^*** INICIO PROCEDIMIENTO:  -->/
        localpp["prepararProc->"] = ""                  if localpp =~ /^prepararProc->/
        localpp["prepararProc--->"] = ""                if localpp =~ /^prepararProc--->/
        localpp["INICIO PROCEDIMIENTO -"] = ""          if localpp =~ /^INICIO PROCEDIMIENTO -/
        localpp["--->INICIO PROCEDIMIENTO:"] = ""       if localpp =~ /^--->INICIO PROCEDIMIENTO:/
        localpp["---> INICIO PROCEDIMIENTO "] = ""      if localpp =~ /^---> INICIO PROCEDIMIENTO/
        localpp["Proceso:"] = ""                        if localpp =~ /^Proceso:/

        localpp
    end

end
