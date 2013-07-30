#!/usr/local/bin/ruby

# Tony's humble blog backup script.
# March 2011. 

require 'rubygems'
require 'net/ssh'
require 'net/scp'
require 'fileutils'
require 'pony'

DEBUG = false

REMOTE_HOST = ''
USERNAME = ''
PASSWD = ''
PORT = 22

DB_USER = ''
DB_NAME = ''
DB_HOST = ''
DB_PASSWD = ''



backup_dir = '/backups/blog'
directory_name = Time.now.strftime('%Y_%B')
backup_file_name = 'backup_' + Time.now.strftime('%Y%m%d')




Net::SSH.start(REMOTE_HOST, USERNAME, :password => PASSWD, :port => PORT) do |ssh|

	unless File.directory?("#{backup_dir}/#{directory_name}")
		FileUtils.mkdir("#{backup_dir}/#{directory_name}")
	end
	home_directory = ssh.exec!('pwd')
	home_directory.chomp!
 
	db_backup = ssh.exec!("mysqldump -u #{DB_USER} -h #{DB_HOST} --password='#{DB_PASSWD}' #{DB_NAME} > #{REMOTE_HOST}_#{backup_file_name}.sql && gzip #{REMOTE_HOST}_#{backup_file_name}.sql")
	puts db_backup if DEBUG # should be blank since mysqldump only gives STDERR

	site_backup = ssh.exec!("tar -cvzf #{home_directory}/#{backup_file_name}_html.tar.gz html")	
	puts site_backup if DEBUG

	ssh.scp.download!("#{home_directory}/#{backup_file_name}_html.tar.gz", "#{backup_dir}/#{directory_name}/#{backup_file_name}", :recursive => true, :preserve => true, :verbose => true)
	ssh.scp.download!("#{home_directory}/#{REMOTE_HOST}_#{backup_file_name}.sql.gz", "#{backup_dir}/#{directory_name}/#{backup_file_name}", :recursive => true, :preserve => true, :verbose => true)

	db_removal = ssh.exec!("rm -rf #{home_directory}/#{REMOTE_HOST}_#{backup_file_name}.sql.gz")
	puts db_removal if DEBUG
	
	site_removal = ssh.exec!("rm -rf #{home_directory}/#{backup_file_name}_html.tar.gz") 
	puts site_removal if DEBUG

	Pony.mail(:to => 'root@rubyninja.org', :from => 'abaltazar_backcup@rubyninja.net', :subject => "#{REMOTE_HOST} backup for " + Time.now.strftime('%m-%d-%Y'), :body => "#{db_backup}\n#{site_backup}\n#{db_removal}\n#{site_removal}")

end
