
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

        def cmd_du(arg)
            human = false # human readable mode
            if not (arg.nil? or arg.empty?) and arg =~ /^(\s*-h)(.*)$/ then
                human = true
                arg = $2.strip
            end
            ret = @hadoop.du(arg)
            if ret.error? and ret.stderr =~ /No such file or directory/ then
                puts ret.stderr
                return
            end
            tot = 0
            ret.stdout.split(/\n/).each do |d|
                if d =~ /^(\d+)\s*(.*)$/ then
                    tot += $1.to_i
                    if human then
                        puts to_human_readable($1.to_i) + "\t\t" + $2
                    else
                        puts d
                    end
                else
                    puts d
                end
            end
            if human then
                puts "#{to_human_readable(tot)} total"
            else
                puts "#{tot} bytes total"
            end
        end


        private

        def to_human_readable(n)
            n = n.to_i
            return "0B" if n == 0

            count = 0
            while  n >= 1024 and count < 4
                n /= 1024.0
                count += 1
            end
            format("%.1f",n) + %w(B K M G T)[count]
        end

        def register_commands

            command 'ls' do |arg|
                cmd_ls(arg)
            end

            command 'cd' do |arg|
                cmd_cd(arg)
            end

            command 'du' do |arg|
                cmd_du(arg)
            end

        end

    end # Client

end # HCC

HCC::Client.new.start!
