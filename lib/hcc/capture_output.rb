
module Kernel

    def capture_output

        newout = Tempfile.new("shell-")
        oldout = STDOUT.dup
        STDOUT.reopen newout

        newerr = Tempfile.new("shell-")
        olderr = STDERR.dup
        STDERR.reopen newerr

        yield

        STDOUT.reopen oldout
        STDERR.reopen olderr

        [ File.new(newout.path).read, File.new(newerr.path).read ]

    ensure
        STDOUT.reopen oldout
        STDERR.reopen olderr
    end

end
