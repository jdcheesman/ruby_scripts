

class Call

    attr_accessor :minute
    attr_accessor :call_count
    attr_accessor :error_count
    attr_accessor :portlet_count

    def initialize(minute)
        @minute = minute
        @call_count = 0
        @error_count = 0
        @portlet_count = 0
    end


    def add_call
        @call_count += 1
    end

    def add_error
        @error_count += 1
    end

    def add_portlet
        @portlet_count += 1
    end
end
