
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
            jars = get_jars(@home) + get_jars(File.join(@home, "lib")) + get_jars(local_lib)
            @classpath = jars.join(":")

            Rjb::load(@classpath)
            shellclass = Rjb::import('hcc.RubyFsShell')
            @shell = shellclass.new( Rjb::import('org.apache.hadoop.conf.Configuration').new )
        end

        def get_jars(path)
            jars = []
            return jars if not File.directory? path
            Dir.entries(path).each do |f|
                f = File.join(path, f)
                next if not File.file? f or not f =~ /\.jar$/
                jars << f
            end
            jars
        end

    end

end # HCC
