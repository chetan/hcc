
require 'cinatra'
require 'colorize'

class Cinatra
    def start
        while !exiting && buf = Readline.readline(HADOOP.prompt, true)
            call(buf)
        end
    end
end

HADOOP = HCC::Hadoop.new

module HCC

    class Client

        def start!

            @hadoop = HADOOP

            register_commands()

            puts "hadoop command-line client v#{HCC::VERSION}"
            puts "type 'help' for help"

        end

        def cmd_ls(arg)

            ret = @hadoop.ls(arg)
            if ret.error? then
                if ret.stderr =~ /No such file or directory/ then
                    puts ret.stderr
                else
                    puts "error running command: #{ret.cmd} - #{ret.stderr}"
                end
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

        def cmd_cd(arg)
            ret = @hadoop.cd(arg)
            if ret.error? and ret.stderr =~ /No such file or directory/ then
                puts ret.stderr
            end
        end


        private

        def register_commands

            command 'ls' do |arg|
                cmd_ls(arg)
            end

            command 'cd' do |arg|
                cmd_cd(arg)
            end

        end

    end # Client

end # HCC

HCC::Client.new.start!
