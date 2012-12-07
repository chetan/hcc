
require 'rjb'
require 'tempfile'

module HCC

    class Output

        attr_reader :cmd, :stdout, :stderr, :code

        def initialize(cmd, stdout, stderr, code)
            @cmd    = cmd
            @stdout = stdout
            @stderr = stderr
            @code   = code
        end

        def success?
            @code == 0
        end

        def error?
            @code != 0
        end

    end

    class Shell

        attr_reader :shell

        def initialize(hadoop_home)

            @home = hadoop_home
            load_rjb()

        end

        # returns Output class
        def run(cmd)
            code = 0
            out, err = capture_output do
                code = @shell.run(cmd)
            end
            Output.new(cmd.join(" "), out, err, code)
        end

        def load_rjb()

            if not ENV["JAVA_HOME"] then
                puts "JAVA_HOME not set! export or pass with --java_home"
                exit
            end

            local_lib = File.expand_path(File.join(File.dirname(__FILE__), "../../lib-java"))
            jars = get_jars(@home, File.join(@home, "lib"), File.join(@home, "client"), local_lib)
            @classpath = jars.join(":")

            Rjb::load(@classpath, [ "-Dlog4j.configuration=/root/hcc/log4j.properties"] )
            conf = Rjb::import('org.apache.hadoop.conf.Configuration').new

            [ File.join(@home, "etc/hadoop/core-site.xml"),
              "/etc/hadoop/conf/core-site.xml" ].each do |p|

                next if not File.directory? p
                path = Rjb::import('org.apache.hadoop.fs.Path').new(p)
                conf._invoke("addResource", "Lorg.apache.hadoop.fs.Path;", path)
            end
            @shell = Rjb::import('hcc.RubyFsShell').new(conf)
        end

        def get_jars(*paths)
            jars = []
            paths.each do |path|
                next if not File.directory? path
                Dir.entries(path).each do |f|
                    f = File.join(path, f)
                    next if not File.file? f or not f =~ /\.jar$/
                    jars << f
                end
            end
            jars
        end

    end

end # HCC
