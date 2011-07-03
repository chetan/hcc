
module HCC

    class Hadoop

        attr_reader :home, :uri, :user, :path

        def initialize(opts={})

            @home = opts[:home] || ENV["HADOOP_HOME"]
            @user = opts[:user] || `whoami`.strip
            @uri  = opts[:uri] || "hdfs://localhost:9000/"
            @path = "/"

            ret = exec(cmd())
            if not (ret.exit_code == 1 and ret.stdout =~ /Usage:/) then
                puts "hadoop command not available"
                exit
            end

        end

        def prompt
            [ "#{@user}@hadoop".colorize(:green), @path.colorize(:blue), "$ " ].join(" ")
        end

        def exec(cmd)
            HCC::Exec.execute(cmd)
        end

        def run_cmd(str)
            exec(cmd(str))
        end

        def cmd(c=nil)
            cmd = ""
            cmd = "#{@home}/bin/" if @home
            cmd += "hadoop"
            cmd += " #{c}" if c
            cmd
        end

        def resolve_path(str)
            if str == nil or str.strip.empty? then
                str = "/"
            elsif str !~ /^\// then
                str = @path + "/" + str
            end
            File.expand_path(str).squeeze("/")
        end

        def ls(str=nil)
            if str.nil? or str.strip.empty?
                str = @path
            else
                str = resolve_path(str)
            end
            run_cmd("fs -ls #{@uri}#{str}")
        end

        def cd(str)
            ret = ls(str)
            return ret if ret.error? # don't update path
            @path = resolve_path(str)
            puts "new path: #{@path}"
            ret
        end

    end

end

