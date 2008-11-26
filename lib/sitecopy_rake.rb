#!/usr/bin/env ruby
#
# (c) 2006-2008, Levin Alexander <http://levinalex.net>
#
# This library is released under the same license as ruby itself.
#
module Rake #:nodoc:

  # This is an interface to the sitecopy program
  #
  # it uses sitecopy to keep a local directory syncronized with
  # a FTP or webDAV server
  #
  # Example usage
  # -------------
  #
  #   rcfile = <<-EOF
  #     server ftp.example.com
  #     username example
  #     password 12345
  #     ...
  #   EOF
  #   t = Rake::SitecopyTask.new("site", rcfile)
  #
  # it generates rake tasks to download, upload or check the
  # contents on the remote server
  #
  # see `rake --tasks` for information the generated rules
  #
  class SitecopyTask

    def initialize(name, rcfile)
      @site = name

      # Sitecopy configuration
      @rc = "site #{@site}\n" << rcfile

      @rcfile = ".sitecopyrc.tmp"
      @state_dir = ".sitecopy.tmp"

      # sitecopy-command
      @sitecopy = "sitecopy -r #{@rcfile} -p #{@state_dir} "

      define
    end

    def fetch
      sh "#{@sitecopy} --fetch #{@site}"
    end

    # list all differences between the local files and the
    # remote copy
    #
    def list
      sh "#{@sitecopy} --list #{@site}"
    end

    # update the remote copy of this site
    #
    def upload
      sh "#{@sitecopy} --update #{@site}"
    end

    # update the local site from the remote copy
    # WARNING: this will overwrite local files
    #
    def download
      sh "#{@sitecopy} --synchronize #{@site}"
    end

    def define
      # Create sitecopy .rcfile
      file @rcfile do
        File.open(@rcfile,"w+", 0600) { |f| f.write(@rc) }
      end

      # Create sitecopy storage directory
      file @state_dir do
        Dir.mkdir(@state_dir, 0700)
        fetch # check state on server
      end

      # Remove sitecopy configfile and state cache
      task :clobber_sitecopy do
        rm_r @state_dir rescue nil
        rm @rcfile rescue nil
      end

      task :prepare_sitecopy => [@rcfile, @state_dir]

      desc "Resyncronize sitecopy state with remote server"
      task :check_server => [:clobber_sitecopy, :prepare_sitecopy] do
        list
      end
      desc "List changes between local directory and remote server"
      task :list => [:prepare_sitecopy] do
        list
      end

      task "upload_#{@site}" => [:prepare_sitecopy] do
        upload
      end
      desc "Upload all sites to remote server"
      task :upload => ["upload_#{@site}"]

      task "download_#{@site}" => [:prepare_sitecopy] do
        download
      end
      desc "Download all sites from remote server"
      task :download => ["download_#{@site}"]

      desc "Clean temporary files"
      task :clobber => [:clobber_sitecopy]
    end
  end
end
