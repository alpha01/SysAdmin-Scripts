#!/usr/bin/ruby -w

# Ruby implementation of the GNU watch command line utility for Mac OS X.
# Written by: Tony Baltazar. June 2010.
# Email: root[@]rubyninja.net

if ARGV.length == 0
        puts 'Syntax: watch.rb <unix commands>'
        puts 'If command contains parameters, make sure to enclose them with single quotes'
        exit
else
        command = ARGV.shift
end

# equivalent to watch -n 1 command
while 1 do
        system "#{command}"
        sleep(1)
        system "clear"

        print "'Ctrl + C': to end this program.......\n\n\n"
end
