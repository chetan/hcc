
module HCC

    class Command

        attr_reader :flags, :paths, :pipe, :args

        def initialize(args=nil)

            return if args.nil?

            # handle pipe
            if args =~ /^(.*?)\s*\|\s+(.*?)\s*$/ then
                @pipe = $2
                args = $1
            end

            # handle flags
            @flags = []
            while args =~ /^\s*(-[a-zA-Z0-9])\s+(.*)$/ do
                @flags << $1
                args = $2
            end

            # rest is path(s)
            @paths = args

        end

        alias_method :path, :paths

        def pipe?
            not @pipe.nil?
        end

    end

end
