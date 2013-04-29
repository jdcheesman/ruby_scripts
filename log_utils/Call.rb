

class Call

    attr_accessor :minute
    attr_accessor :call_count
    attr_accessor :error_count
    attr_accessor :total_time

    attr :starttime
    attr :last_call

    def initialize(minute, starttime)
        @minute = minute
        @starttime = starttime
        @last_call = starttime
        @call_count = 0
        @error_count = 0
        @portlet_count = 0
        @total_time = 0
    end


    def add_call
        @call_count += 1
    end

    def add_error
        @error_count += 1
    end

    def add_time(time_to_add)
        @total_time = @total_time + (time_to_add - last_call)
        @last_call = time_to_add
    end
end
