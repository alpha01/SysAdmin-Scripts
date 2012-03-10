#!/usr/bin/ruby -w

# Simple Ruby script which uses the HandBreak's command line utility
# to fully automate video re-encoding for an iPhone or iPod Touch.
#
# Written by: Tony Baltazar. June 2010.
# Email: root[@]rubyninja.org
# Version: 0.1

require 'find'



class IphoneVideoEncoding

  attr_accessor :itunes_dir

  def initialize(videos)
    @videos = videos
  end


  def vid_formats()
    vid_formats = ['mov', 'avi', 'flv']
  end


  def encode
    Find.find(@videos) do |movie_files|

      next if File.directory?(movie_files)

      encoded_vid_full_path = File.expand_path(movie_files)
      encoded_vids_arr = movie_files.split('/').to_a
      
      encoded_vid_title = encoded_vids_arr[0]
      encoded_vid_full = encoded_vids_arr.pop
      encoded_vid_dir = encoded_vids_arr.pop
      
      vid_ext = encoded_vid_full.slice(-3, 3)
      count = encoded_vid_full.length - 4
      encoded_vid = encoded_vid_full[0, count.to_i]


      final_encoded_vid_full_path = Regexp.escape(encoded_vid_full_path)
      final_encoded_vid_title = Regexp.escape(encoded_vid_title)
      final_encoded_vid = Regexp.escape(encoded_vid)

      if vid_formats.include?(vid_ext)

        system "/usr/bin/HandBrakeCLI --verbose --preset 'iPhone & iPod Touch' -i #{final_encoded_vid_full_path} -o #{itunes_dir}#{final_encoded_vid_title}_#{final_encoded_vid}.mp4"

      end
  
    end

  end


end

################################################
# Comment this out to make it more cron friendly
if ARGV.length == 0
  print "Syntax: <media directory>\n"
  exit
else
  videos = ARGV.shift
end
################################################

video_dir = IphoneVideoEncoding.new(videos)
video_dir.itunes_dir = Regexp.escape('/Users/USERNAME/Music/iTunes/iTunes Media/Automatically Add to iTunes/')
video_dir.encode
