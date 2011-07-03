
require 'cinatra'
require 'colorize'

class Cinatra
    def start
        while !exiting && buf = Readline.readline(HADOOP.prompt, true)
            call(buf)
        end
    end
end

puts "hadoop command-line client v#{HCC::VERSION}"
puts "type 'help' for help"

HADOOP = HCC::Hadoop.new
@hadoop = HADOOP

command 'ls' do |arg|
    ret = @hadoop.ls(arg)
    if ret.error? then
        puts "error running command: #{ret.cmd} - #{ret.stderr}"
        return
    end
    c = 0
    ret.stdout.split(/\n/).each do |f|
        c += 1
        if c == 1
            puts f
            next
        end
        # TODO: handle filenames with spaces (possibly multiple spaces)
        s = f.split(/\s+/)
        (perm, repl, user, group, size, date, time) = s
        file = s[7..s.length].join(" ")
        file.sub!(@hadoop.path + "/", '')
        if perm =~ /^d/ then
            file = file.colorize(:blue)
        end
        puts [perm, repl, user, group, size, date, time, file].join("\t")

    end

end

command 'cd' do |arg|
    ret = @hadoop.cd(arg)
    if ret.error? then
        puts "invalid path: arg"
        return
    end
end
