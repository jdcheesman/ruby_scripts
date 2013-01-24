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
            @params = callparams.chomp.strip
            @worst = elapsed
        end
        @calls = @calls + 1
        @totaltime = @totaltime + elapsed
    end
end
