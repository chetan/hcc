
require 'open4'

# original code from gem 'arh'

module HCC
    class Exec

        attr_reader :start_at
        attr_reader :end_at

        attr_reader :cmd
        attr_reader :stdout
        attr_reader :stderr
        attr_reader :exit_code
        attr_reader :status
        attr_reader :pid

        def self.execute(shell_command)
            new(shell_command).execute
        end

        def self.execute!(shell_command)
            new(shell_command).execute!
        end

        def execute!
            @raise_on_fail = true
            execute
        end

        def initialize(shell_command)
            raise ArgumentError, "no command given" unless shell_command
            @cmd = shell_command
        end

        def execute

            puts "run> #{@cmd}"

            @start_at = Time.now

            begin
                pid_open4, stdin, stdout, stderr = Open4::popen4 @cmd

            rescue => ex
                @stderr    = ex.message
                @exit_code = -1
                @end_at    = Time.now
                return self
            end

            ignored, status_open4 = Process::waitpid2 pid_open4

            @status = status_open4
            @stdout = stdout.read
            @stderr = stderr.read

            @end_at    = Time.now
            @exit_code = @status.exitstatus
            @pid       = pid_open4

            self
        end

        def success?
            @exit_code.zero?
        end

        def error?
            not @exit_code.zero?
        end
    end

end # HCC
