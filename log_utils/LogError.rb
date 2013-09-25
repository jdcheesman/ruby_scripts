class LogError
    attr_accessor :time
    attr_accessor :code
    attr_accessor :description
    attr_accessor :java_method
    attr_accessor :java_class
    attr_accessor :normalisedTime
    IDENTICAL_TIME_DELTA = 5

    def initialize(time, description, java_id, normalisedTime)
        @time = time
        @description = description
        @normalisedTime = normalisedTime
        set_error_code(description)
        set_java_id(java_id)
    end

    def set_error_code(description)
        if description =~ /^ORA/
            if description =~/[:]/
                dd = description.split(':')
                @code = dd[0]
                @description = dd[1]
            else
                slicedCode = /^(ORA\-[0-9]+) ([\w\W]+)$/.match(description)
                @code = slicedCode[1]
                @description = slicedCode[2]
            end
        else
            @code = "-"
        end
    end

    def set_java_id(java_id)
        slicedJava = /([a-zA-Z\.]+)\.([a-zA-Z]+)/.match(java_id)
        @java_class = slicedJava[1]
        @java_method = slicedJava[2]
    end

    def same?(other)
        other.description.include?(description) and (normalisedTime - other.normalisedTime) < IDENTICAL_TIME_DELTA
    end

end