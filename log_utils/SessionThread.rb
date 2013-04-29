class SessionThread
    attr_accessor :id
    attr_accessor :in_proc
    attr_accessor :start_time
    attr_accessor :end_time

    attr_accessor :real_start_time
    attr_accessor :real_end_time
    attr_accessor :msgs
    attr_accessor :javas

    @@cut_off = 5000 # 5 seconds
    @@absolute_cut_off = 60 * 60 * 1000


    def initialize(id, start_time, real_start_time)
        @id = id.split('.')[-2]
        @real_start_time = real_start_time
        @in_proc = false

        @start_time = start_time.to_i

        @end_time = Array[]
        @real_end_time = Array[]
        @javas = Array[]
        @msgs = Array[]
    end

    def update(time, real_time, java, msg)
        @end_time << time.to_i
        @real_end_time << real_time
        @javas << java

        if @id !~ /Portlet/
            java_id = java.split('.')[-2]
            if java_id =~ /[a-z]Portlet/
                @id = java_id
            end
        end
        @msgs << msg
    end


    def can_kill_thread(time)
        if time == nil || end_time == nil
            false
        else
            check_time_and_in_proc(time.to_i - @end_time[-1])
        end
    end

    def elapsed()
        @end_time[-1].to_i - @start_time
    end


    def check_time_and_in_proc(elapsed_time)
        result =
            (!@in_proc and elapsed_time > @@cut_off) or
            ((@javas[-1]+" "+@msgs[-1]).downcase =~ /renderbody===>.*inicio / and elapsed_time > @@cut_off) or
            (elapsed_time > @@absolute_cut_off)
        if result
            @real_end_time.pop
            @end_time.pop
            @msgs.pop
            @javas.pop
            # printf("[%s] DONE  check_time_and_in_proc. elapsed_time=%d, in_proc=%s\n", @real_end_time[-1], elapsed_time, @in_proc)
        # else
        #     printf("[%s] !DONE check_time_and_in_proc. elapsed_time=%d, in_proc=%s\n", @real_end_time[-1], elapsed_time, @in_proc)
        end
        result
    end
end