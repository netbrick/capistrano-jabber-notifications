require 'xmpp4r'
require 'xmpp4r/roster/helper/roster'

module Capistrano
  module Jabber
    module Notifications
      class << self
        attr_accessor :options

        def deploy_started
          send_jabber_message "deploy"
        end

        def deploy_completed
          send_jabber_message "deploy", true
        end

        def rollback_started
          send_jabber_message "deploy:rollback"
        end

        def rollback_completed
          send_jabber_message "deploy:rollback", true
        end

        private

        def git_log_revisions
          current, real = options[:current_revision][0,7], options[:real_revision][0,7]

          if current == real
            "GIT: No changes ..."
          else
            if (diff = `git log #{current}..#{real} --oneline`) != ""
              diff = "  " << diff.gsub("\n", "\n    ") << "\n"
              "\nGIT Changes:\n" + diff
            else
              "GIT: Git-log problem ..."
            end
          end
        end

        def send_jabber_message(action, completed = false)
          msg = []
          msg << "#{completed ? 'Completed' : 'Started'} #{action} on #{options[:stage]} by #{username}"
          msg << "Time: #{Time.now.to_s}"
          msg << "Application: #{options[:application]}"
          msg << "Branch: #{options[:branch]}"
          # msg << "Revision #{options[:real_revision]}"
          # msg << "Release name #{options[:release_name]}"
          # msg << git_log_revisions if options[:source].to_sym == :git
          msg = msg.join("\r\n")

          client = ::Jabber::Client.new(options[:uid].to_s)
          client.connect(options[:server].to_s)
          client.auth(options[:password].to_s)
          notification_group = options[:group].to_s
          notification_list = options[:members]

          roster = ::Jabber::Roster::Helper.new(client)

          mainthread = Thread.current
          roster.add_query_callback { |iq| mainthread.wakeup }
          Thread.stop

          roster.find_by_group(notification_group).each {|item|
            client.send(item.jid)
            m = ::Jabber::Message.new(item.jid, msg).set_type(:normal).set_id('1').set_subject('deploy')
            client.send(m)
          }

          notification_list.each { |member|
            client.send(member)
            m = ::Jabber::Message.new(member, msg).set_type(:normal).set_id('1').set_subject('deploy')
            client.send(m)
          }

          client.close
          true
        end

        def username
          @username ||= [`whoami`, `hostname`].map(&:strip).join('@')
        end
      end
    end
  end
end

set :current_revision, lambda { `git rev-parse #{fetch :branch}`.chomp }

namespace :deploy do
  namespace :jabber do
    %w(deploy_started deploy_completed rollback_started rollback_completed).each do |m|
      task m.to_sym do
        Capistrano::Jabber::Notifications.options = {
          uid:      fetch(:jabber_uid),
          server:   fetch(:jabber_server),
          password: fetch(:jabber_password),
          group:    fetch(:jabber_group),
          members:  fetch(:jabber_members),
          real_revision: fetch(:real_revision),
          release_name: fetch(:release_name),
          action: m.to_sym,
          current_revision: fetch(:current_revision),
          branch: fetch(:branch),
          application: fetch(:application),
          stage: fetch(:stage),
          source: fetch(:scm),
          real_revision: fetch(:real_revision)
        }

        Capistrano::Jabber::Notifications.send m
      end
    end
  end

  # Deploy tasks
  before 'deploy', 'deploy:jabber:deploy_started'
  after  'deploy', 'deploy:jabber:deploy_completed'
  before 'deploy:rollback', 'deploy:jabber:rollback_started'
  after  'deploy:rollback', 'deploy:jabber:rollback_completed'
end
