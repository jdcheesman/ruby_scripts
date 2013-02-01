

class Call

    attr_accessor :minute
    attr_accessor :call_count
    attr_accessor :error_count

    def initialize(minute)
        @minute = minute
        @call_count = 0
        @error_count = 1
    end


    def add_call
        @call_count += 1
    end

    def add_error
        @call_count += 1
        @error_count += 1
    end
end
