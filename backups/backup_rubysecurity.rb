#!/usr/local/bin/ruby

# Tony's humble rubysecurity.org backup script.
# February 2012. 

require 'rubygems'
require 'fileutils'
require 'pony'

DEBUG = false

$REMOTE_HOST = ''
$USERNAME = ''
$PORT = ''

 
def site_backup(db_user, db_name, db_host, db_passwd, site=nil)

	backup_dir = '/server/rubysecurity.org'
	directory_name = Time.now.strftime('%Y_%B')
	backup_file_name = 'backup_' + Time.now.strftime('%Y%m%d')

	unless File.directory?("#{backup_dir}/#{directory_name}/#{backup_file_name}")
        	FileUtils.mkdir_p("#{backup_dir}/#{directory_name}/#{backup_file_name}")
	end

	# remote dir
	home_directory = '/home/HOMEDIRECTORYHERE'



	if site 
		site_backup = `ssh -p #$PORT #$USERNAME@#$REMOTE_HOST 'tar -cvzf #{home_directory}/#{backup_file_name}_public_html.tar.gz #{home_directory}/public_html'`
		puts site_backup if DEBUG

		system("scp -P#$PORT #$USERNAME@#$REMOTE_HOST:#{home_directory}/#{backup_file_name}_public_html.tar.gz #{backup_dir}/#{directory_name}/#{backup_file_name}/")

		system("ssh -p #$PORT #$USERNAME@#$REMOTE_HOST 'rm -rf #{home_directory}/#{backup_file_name}_public_html.tar.gz'") 
	end


	system("ssh -p #$PORT #$USERNAME@#$REMOTE_HOST 'mysqldump -u #{db_user} -h #{db_host} --password=\'#{db_passwd}\' #{db_name} > #{db_name}_#{backup_file_name}.sql && gzip #{db_name}_#{backup_file_name}.sql'")

	system("scp -P#$PORT #$USERNAME@#$REMOTE_HOST:#{home_directory}/#{db_name}_#{backup_file_name}.sql.gz #{backup_dir}/#{directory_name}/#{backup_file_name}/")

	system("ssh -p #$PORT #$USERNAME@#$REMOTE_HOST 'rm -rf #{home_directory}/#{db_name}_#{backup_file_name}.sql.gz'")
	

	Pony.mail(:to => 'root@rubyninja.org', :from => 'rubysecurity_backup@rubyninja.net', :subject => "#$REMOTE_HOST backup for " + Time.now.strftime('%m-%d-%Y'), :body => "#{site_backup}")

end



# Drupal
site_backup('DB_NAME', 'DB_USERNAME', 'localhost', 'PASSWD_HERE', true)
# Gallery
site_backup('DB_NAME', 'DB_USERNAME', 'localhost', 'PASSWD_HERE')
