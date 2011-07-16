
require 'rjb'
require 'tempfile'

module HCC

    class Output

        attr_reader :cmd, :stdout, :stderr

        def initialize(cmd, stdout, stderr)
            @cmd    = cmd
            @stdout = stdout
            @stderr = stderr
        end

        def success?
            @stderr.empty?
        end

        def error?
            not @stderr.empty?
        end

    end

    class Shell

        def initialize(hadoop_home)

            @home = hadoop_home
            load_rjb()

        end

        # returns Output class
        def run(cmd)
            out, err = capture_output do
                @shell.run(cmd)
            end
            Output.new(cmd.join(" "), out, err)
        end

        def load_rjb()

            if not ENV["JAVA_HOME"] then
                puts "JAVA_HOME not set! export or pass with --java_home"
                exit
            end

            jars = get_jars(File.join(@home)) + get_jars(File.join(@home, "lib"))
            @classpath = jars.join(":")

            Rjb::load(@classpath)
            shellclass = Rjb::import('org.apache.hadoop.fs.FsShell')
            @shell = shellclass.new( Rjb::import('org.apache.hadoop.conf.Configuration').new )
        end

        def get_jars(path)
            jars = []
            Dir.entries(path).each do |f|
                f = File.join(path, f)
                next if not File.file? f or not f =~ /\.jar$/
                jars << f
            end
            jars
        end

    end

end # HCC
