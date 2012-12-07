

VERSION_NUMBER = File.read(File.join(File.dirname(__FILE__), "VERSION"))
GROUP = "hcc"
VENDOR = "Pixelcop Research, Inc."
URL = "https://github.com/chetan/hcc"

# Specify Maven 2.0 remote repositories here, like this:
repositories.remote << "http://mirrors.ibiblio.org/pub/mirrors/maven2"
repositories.remote << "https://repository.cloudera.com/content/repositories/releases/"

class Buildr::Artifact
  def <=>(other)
    self.id <=> other.id
  end
end

def add_artifacts(*args)
  artifacts( [ args ].flatten.reject{|j| j =~ /:pom:/}.sort.uniq ).sort
end

require 'lock_jar'
JARS = add_artifacts(LockJar.list(%w{compile}))

desc "hcc"
define "hcc" do

  project.version = VERSION_NUMBER
  project.group   = GROUP

  manifest["Implementation-Vendor"]  = VENDOR
  manifest["Implementation-URL"]     = URL
  manifest["Implementation-Version"] = VERSION_NUMBER
  manifest["Build-Date"]             = Time.new.to_s
  manifest["Copyright"]              = "#{VENDOR} (C) #{Time.new.strftime('%Y')}"
  manifest["Build-Jdk"]              = `javac -version`

  compile.with JARS
  resources
  package(:jar)
end

# Backward compatibility:  Buildr 1.4+ uses $HOME/.buildr/buildr.rb
local_config = File.expand_path('buildr.rb', File.dirname(__FILE__))
load local_config if File.exist? local_config
