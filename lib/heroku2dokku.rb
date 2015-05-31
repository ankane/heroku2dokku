require "heroku2dokku/version"
require "shellwords"
require "set"
require "git"

module Heroku2Dokku
  class Client
    def run(args)
      case args[0]
      when "all"
        app
        config
        domains
        checks
      when "app"
        app
      when "checks"
        checks
      when "config"
        config
      when "domains"
        domains
      else
        puts %(Usage: heroku2dokku COMMAND

Options:
    all
    app
    checks
    config
    domains

)
        exit 2
      end
    end

    private

    def dokku_run(command, log = false)
      log_info "dokku #{command}" if log
      ret = `~/.dokku/contrib/dokku_client.sh #{command} 2> /dev/null`
      # puts ret
      ret
    end

    def heroku_run(command)
      `heroku #{command}`
    end

    def log(message)
      puts "-----> #{message}..."
    end

    def log_info(message)
      puts "       #{message}"
    end

    def checks
      log "Creating checks"

      if File.exist?("CHECKS")
        log_info "CHECKS exists"
      else
        doc = "WAIT=5\nATTEMPTS=6\n/\n"
        File.open("CHECKS", "w") { |f| f.write(doc) }
      end
    end

    def config
      log "Adding config"

      lines = heroku_run("config").lines.map(&:chomp)[1..-1]
      dokku_lines = dokku_run("config").lines.map(&:chomp)[1..-1]
      existing_keys = Set.new
      dokku_lines.each do |line|
        key, value = line.split(/:\s+/, 2)
        existing_keys << key
      end
      command = "config:set"
      env = {}
      lines.each do |line|
        key, value = line.split(/:\s+/, 2)

        unless existing_keys.include?(key) || key == "PGBACKUPS_URL" || key =~ /\AHEROKU_POSTGRESQL_.+_URL\z/
          env[key] = value
        end
      end

      env.each do |key, value|
        command << " \\\n          #{Shellwords.escape(key)}=#{Shellwords.escape(value)}"
      end

      if env.any?
        dokku_run command, true
      else
        log_info "No config to sync"
      end
    end

    def domains
      log "Adding domains"
      heroku_domains = heroku_run("domains").lines.map(&:chomp)[1..-1].reject { |s| s.empty? || s =~ /\.herokuapp\.com\z/ }
      dokku_domains = dokku_run("domains").lines.map(&:chomp)[1..-1].reject(&:empty?)
      sync_domains = heroku_domains - dokku_domains
      if sync_domains.empty?
        log_info "No domains to sync"
      end
      sync_domains.each do |domain|
        dokku_run "domains:add #{domain}", true
      end
    end

    def app
      log "Creating app"
      dokku_apps = dokku_run("apps").lines.map(&:chomp)[1..-1]
      g = Git.open(".")
      app = g.remotes.find { |r| r.name == "dokku" }
      if app
        app = app.url.split(":").last
      end

      unless app
        log_info "First run: git remote add dokku dokku@dokkuhost:app"
        abort
      end

      if dokku_apps.include?(app)
        log_info "App exists: #{app}"
      else
        dokku_run "apps:create #{app}", true
      end
    end
  end
end
