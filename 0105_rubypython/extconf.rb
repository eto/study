require 'mkmf'

py_prefix     = with_config("python-prefix", "/usr/local")
py_includedir = py_prefix + "/include/python1.5"
py_libdir     = py_prefix + "/lib/python1.5"
py_configdir  = py_libdir + "/config"

$CFLAGS  = "-I#{py_includedir}"
$LDFLAGS = "-L#{py_configdir}"

# If python is linked with extra libraries (e.g. -lpthread on Linux,
# -lsocket on Solaris, etc.), have_library test will fail and built
# python.so may cause runtime error because of lacking those libraries.
# Thus we try to extract LIBS from python Makefile.
# If this also fails, you can specify py_extralibs manually.
py_makefile  = py_configdir + "/Makefile"
py_extralibs = ""
if py_extralibs == ""
  begin
    printf "checking for %s... ", py_makefile
    pymf = File.open(py_makefile)
    if pymf.find {|line| line =~ /^LIBS\s*=\s*(.*)\s*$/}
      py_extralibs = $1
      print "yes\n"
    else
      print "no\n"
    end
    pymf.close
  rescue
    print $!, "\n" if $DEBUG
    print "no\n"
  end
end
$libs = py_extralibs + " " + $libs if py_extralibs

if have_library("python1.5", "Py_Initialize") && have_header("Python.h")
  create_makefile("python")
end
