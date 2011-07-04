
require 'rjb'

module HCC

    class Output

        attr_reader :stdout
        attr_reader :stderr

        def initialize(stdout, stderr)
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
            Output.new(out, err)
        end

        def capture_output

            ord, owr = IO.pipe
            oldout = STDOUT.dup
            STDOUT.reopen owr

            erd, ewr = IO.pipe
            olderr = STDERR.dup
            STDERR.reopen ewr

            yield

            STDOUT.reopen oldout
            STDERR.reopen olderr

            owr.close
            ewr.close

            [ ord.read, erd.read ]

        ensure
            STDOUT.reopen oldout
            STDERR.reopen olderr
        end

        def load_rjb()
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
