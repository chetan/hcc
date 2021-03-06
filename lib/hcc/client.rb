
require 'cinatra'
require 'colorize'
require 'tempfile'

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

        def cmd_ls(arg, recursive=false)

            cmd = HCC::Command.new(arg)
            ret = @hadoop.ls(cmd.paths, recursive)

            if ret.error? then
                if ret.stderr =~ /No such file or directory/ then
                    puts ret.stderr
                else
                    puts "error running command (exit code: #{ret.code}): #{ret.cmd} - \n#{ret.stderr}"
                end
                return if ret.stdout.nil? or ret.stdout.empty?
            end

            write_output(cmd) do
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
            end # write_output
        end

        def cmd_cd(arg)
            ret = @hadoop.cd(arg)
            if ret.error? and ret.stderr =~ /No such file or directory/ then
                puts ret.stderr
            end
        end

        def cmd_du(arg)

            cmd = HCC::Command.new(arg)
            human = cmd.flags.include? "-h" # human readable mode
            ret = @hadoop.du(cmd.paths)

            if ret.error? and ret.stderr =~ /No such file or directory/ then
                puts ret.stderr
                return
            end

            write_output(cmd) do
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
            end # write_output
        end

        def cmd_cat(arg)
            cmd = HCC::Command.new(arg)
            ret = @hadoop.cat(cmd.paths)
            if ret.error? and ret.stderr =~ /No such file or directory/ then
                puts ret.stderr
                return
            end
            write_output(cmd, ret)
        end

        def cmd_mkdir(arg)
            cmd = HCC::Command.new(arg)
            ret = @hadoop.mkdir(cmd.paths)
            if ret.error? then
                puts ret.stderr
                return
            end
            write_output(cmd, ret)
        end

        def cmd_rm(arg, recursive=false)
            cmd = HCC::Command.new(arg)
            ret = @hadoop.rm(cmd.paths, recursive)
            if ret.error? then
                puts ret.stderr
                return
            end
            write_output(cmd, ret)
        end

        def cmd_setrep(arg)
            cmd = HCC::Command.new(arg)
            if cmd.paths !~ /^\s*(\d+)\s+(.*)$/ then
                puts "setrep: invalid arguments; try 'help setrep'"
                return
            end
            repl = $1
            path = $2
            recursive = (cmd.flags.include? "-R" or cmd.flags.include? "-r")
            ret = @hadoop.setrep(repl, path, recursive)
            if ret.error? then
                puts ret.stderr
                return
            end
            write_output(cmd, ret)
        end

        def cmd_put(arg)
            cmd = HCC::Command.new(arg)
            ret = @hadoop.put(cmd.paths)
            if ret.error? then
                puts ret.stderr
                return
            end
            write_output(cmd, ret)
        end

        def cmd_get(arg)
            cmd = HCC::Command.new(arg)
            ret = @hadoop.get(cmd.paths)
            if ret.error? then
                puts ret.stderr
                return
            end
            write_output(cmd, ret)
        end


        private


        def write_output(cmd, ret=nil, &block)

            if block_given? then
                out, err = capture_output do
                    yield
                end
                ret = Output.new(nil, out, err, 0)
            end

            if cmd.pipe? then
                pipe_to(ret.stdout, cmd.pipe)
            else
                print ret.stdout
                print ret.stderr
            end

        end

        # cat test/in/tiny.txt
        def pipe_to(output, cmd)
            t = Tempfile.new("hcc-pipe-")
            t.write(output)
            t.close
            fork do
                exec("cat #{t.path} | #{cmd}")
            end
            Process.wait
        end

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

            command 'ls', "list files in path; ls [path]" do |arg|
                cmd_ls(arg)
            end

            command 'lsr', "list files in path, recursively; lsr [path]" do |arg|
                cmd_ls(arg, true)
            end

            command 'cd', "change working directory; cd [path]" do |arg|
                cmd_cd(arg)
            end

            command 'du', "disk usage summary; du [-h] [path ...]" do |arg|
                cmd_du(arg)
            end

            command 'cat', "copies source paths to stdout; cat path [path ...]" do |arg|
                cmd_cat(arg)
            end

            # destructive commands

            command 'mkdir', "creates the given directories; mkdir path [path ...]" do |arg|
                cmd_mkdir(arg)
            end

            command 'rm', "delete files specified as args; rm path [path ...]" do |arg|
                cmd_rm(arg)
            end

            command 'rmr', "recursively delete files specified as args; rmr path [path ...]" do |arg|
                cmd_rm(arg, true)
            end

            command 'setrep', "changes the replication factor of a file; setrep [-R] <repl factor> path" do |arg|
                cmd_setrep(arg)
            end

            command 'put', "copy one or more files to the given remote path; put <local file> [...] <remote dest>" do |arg|
                cmd_put(arg)
            end

            command 'get', "copy one or more files to the given local path; put <remote file> <local dest>" do |arg|
                cmd_get(arg)
            end

        end

    end # Client

end # HCC

HCC::Client.new.start!
