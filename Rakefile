require 'rubygems'
require 'fileutils'

task :default => :buildjrubyjar

$fname    = "mackworth.rb"
$clsname  = "MackworthTestMain.class"

$builddir   = "build"

$metainfdir = "META-INF"
$mfname     = $metainfdir + "/MANIFEST.MF"

$jrubyjar   = "/home/jpace/Downloads/jruby-complete-1.6.3.jar"
$tgtjar     = "mackworth.jar"

def buildfile fname
  File.join($builddir, fname)
end

directory $builddir

directory buildfile($metainfdir)

def copytask fname, deps, taskname
  tgtfile = buildfile(fname)
  file tgtfile => deps do |t|
    cp t.prerequisites.last, t.name
  end
  task taskname => tgtfile
end

def jrubyctask rbfname, taskname
  task taskname do |t|
    sh "jrubyc -t #{$builddir} --javac #{rbfname}"
  end
end

copytask $fname,  [ $fname ], :rubyfile
copytask $mfname, [ buildfile($metainfdir), "jar/#{$mfname}" ], :manifest
copytask $tgtjar, [ $jrubyjar ], :tgtjar

jrubyctask $fname, :rbmain

task :jrubyc => $fname do |t|
  sh "jrubyc -t #{$builddir} --javac #{t.prerequisites.last}"
end

copytask $clsname, [ $clsname ], :javaclass
  
task :buildjrubyjar => [ :manifest, :tgtjar, :rbmain ] do
  Dir.chdir $builddir

  sh "jar ufm #{$tgtjar} #{$mfname} *.class"
end
