class PLSQLProc
    attr_accessor   :name
    attr_accessor   :worst
    attr_accessor   :params
    attr_accessor   :totaltime
    attr_accessor   :calls

    def initialize(name)
        @name = name.chomp.strip
        @worst = 0
        @totaltime = 0
        @calls = 0
    end

    def add_call(elapsed, callparams)
        if elapsed > @worst
            @params = clean_up_params(callparams)
            @worst = elapsed
        end
        @calls = @calls + 1
        @totaltime = @totaltime + elapsed
    end

    def clean_up_params(pp)
        localpp = pp.chomp.strip
        localpp["---> INICIO PROCEDIMIENTO:"] = ""    if localpp =~ /^---> INICIO PROCEDIMIENTO:/
        localpp["*** Inicio Procedimiento -->"] = ""  if localpp =~ /^*** Inicio Procedimiento -->/
        localpp["prepararProc->"] = ""                if localpp =~ /^prepararProc->/
        localpp["INICIO PROCEDIMIENTO -"] = ""        if localpp =~ /^INICIO PROCEDIMIENTO -/
        localpp["--->INICIO PROCEDIMIENTO:"] = ""     if localpp =~ /^--->INICIO PROCEDIMIENTO:/
        localpp["---> INICIO PROCEDIMIENTO "] = ""    if localpp =~ /^---> INICIO PROCEDIMIENTO/
        localpp["Proceso:"] = ""                     if localpp =~ /^Proceso:/

        localpp
    end

end
