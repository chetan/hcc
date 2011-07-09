
module HCC

    class Hadoop

        attr_reader :home, :uri, :user, :path
        attr_reader :shell

        def initialize(opts={})

            @home = opts[:home] || ENV["HADOOP_HOME"]
            @user = opts[:user] || `whoami`.strip
            @uri  = opts[:uri]
            @path = "/"

            # try to locate home dir if not set
            locate_home_dir if not @home
            locate_hdfs if not @uri

            @shell = HCC::Shell.new(@home)
        end

        def prompt
            [ "#{@user}@hadoop".colorize(:green), @path.colorize(:blue), "$ ".colorize(:blue) ].join(" ")
        end

        def exec(cmd)
            HCC::Exec.execute(cmd)
        end

        def run_cmd(str)
            #exec(cmd(str))
            @shell.run( str.split(/ /) )
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
            #run_cmd("fs -ls #{@uri}#{str}")
            run_cmd("-ls #{@uri}#{str}")
        end

        def cd(str)
            ret = ls(str)
            return ret if ret.error? # don't update path
            @path = resolve_path(str)
            #puts "new path: #{@path}"
            ret
        end


        private

        def locate_hdfs
            conf = "/etc/hadoop/conf/core-site.xml"
            if File.exists? conf then
                if `grep 'hdfs://' #{conf}` =~ %r{<value>(.*?)</value>} then
                    @uri = $1
                    return
                end
            end
            @uri = "hdfs://localhost:9000/"
        end

        def locate_home_dir
            h = `which hadoop`.strip
            if h.empty? then
                puts "hadoop command not available"
                exit
            end
            h = File.readlink(h) if File.symlink? h

            e = `grep 'export HADOOP_HOME' #{h}`
            if e and e =~ /^export HADOOP_HOME=['"]?(.*)['"]?/ then
                @home = $1

            elsif h =~ %r{/bin/hadoop$} then
                @home = h.gsub(%r{/bin/hadoop$}, '')
            end
        end

    end

end

