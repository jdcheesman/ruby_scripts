class LogError
    attr_accessor :time
    attr_accessor :code
    attr_accessor :description

    attr_accessor :normalisedTime
    IDENTICAL_TIME_DELTA = 5

    def initialize(time, description, normalisedTime)
        @time = time
        @description = description
        @normalisedTime = normalisedTime
        set_error_code(description)
    end

    def set_error_code(description)
        if description =~ /^ORA/
            dd = description.split(':')
            @code = dd[0]
            @description = dd[1]
        else
            @code = "-"
        end
    end

    def same?(other)
        other.description.include?(description) and (normalisedTime - other.normalisedTime) < IDENTICAL_TIME_DELTA
    end

end