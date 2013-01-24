#!/usr/bin/ruby -w

# Speed up UNIX/Linux shell scripting
# syntax:
# ./rnew.rb scriptname.rb

path  = ARGV[0]
script_type = File.extname(path)

fail 'specify filename to create' unless path

if File.exist?(path)
	puts "#{path} already exists"
	exit
end


File.open(path, 'w') do |f|

        case script_type

                when '.pl'
                        f.print "#!/usr/bin/perl -w\nuse strict;"

                when '.php'
                        f.print "#!/usr/bin/php\n<?php"

                when '.sh'
                        f.print "#!/bin/bash"

                when '.py'

                        f.print "#!/usr/bin/python"

                when '.rb'
                        f.print "#!/usr/bin/ruby"
                else
                        puts "You're not programming using an open source scripting language!"
                        exit
        end

end

File.chmod(0755, path)

system "vim  #{path}"
