
class Error
    attr_accessor :src
    attr_accessor :msg
    attr_accessor :usr

    def initialize(src)
        @src = src
        @msg = Hash[]
        @usr = Hash[]
    end

    def add_msg(msg)
        if @msg[msg]  == nil
            @msg[msg] = 1
        else
            @msg[msg] += 1
        end
    end


    def add_user(usr, date)
        split_date = date.split('/')
        date = "%s/%s/20%s" % [split_date[0], split_date[1], split_date[2]]
        # overwrite any previous data:
        @usr[usr] = date
    end

end
