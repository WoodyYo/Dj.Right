#!/usr/bin/env ruby
require 'sequel'

class DBManager
	def initialize
		@db = Sequel.sqlite('v_server.db')
		@db.create_table? :users do
			String :id, :unique => true, :null => false
			Integer :angry, :default => 0
			Integer :sad, :default => 0
			Integer :happy, :default => 0
			Integer :joyful, :default => 0
		end
		@db.create_table? :messages do
			String :id
			Text :body
			DateTime :time
			FalseClass :read, :default => false
		end
		create_user "woodyyo5566" unless get_by_id "woodyyo5566"  # create super user
	end
	def dropall
		puts "If u r sure to do this, please enter the project's name"
		s = STDIN.readline.split("\n")[0]
		if s == "Dj. Right"
			puts "Got it~"
			@db.drop_table :users
			@db.drop_table :messages
		else
			puts "Screw u"
		end
	end
	def create_user id
		begin
			@db[:users].insert(:id => id)
			msg = "安安，#{id}，歡迎成為小白鼠#{@db[:users].count}號！"
			{:id => id, :angry => 0, :sad => 0, :joyful => 0, :happy => 0, :msgs => [msg]}
		rescue => e  # unique
			puts e
			{}
		end
	end
	def get_by_id userid
		user = @db[:users].where(:id => userid).first
		user[:msgs] = get_all_msgs(userid) if user
		user
	end
	def puts_all_users
		puts @db[:users].all
	end
	def send_msg userid, msg
		if get_by_id userid
			@db[:messages].insert(:id => userid, :body => msg, :time => Time.now)
			true
		else
			false
		end
	end
	def get_all_msgs userid  # only return msgs' body. Setting the flag or not is the server's business!
		msgs = @db[:messages].select(:body).where(:id => userid, :read => false).all
		msgs.collect { |e| e[:body] }
	end
	def read_all_msgs userid  # only set the flag to true
		@db[:messages].where(:id => userid, :read => false).update(:read => true)
	end
	def set_emo_count userid, emo, count
		@db[:user].where(:id => userid).update(emo => count)
	end
	#### ROOT's POWER ####
	def get_db
		@db
	end
	def puts_all_msgs userid
		@db[:messages].where(:id => userid).each { |e| puts e }
	end
	def DBManager.enter_msgs
		s = ''
		while true
			tmp = STDIN.readline
			if tmp == "\n"
				puts "=====new msg====="
				yield s
				s = ''
			else
				s += tmp
			end
		end
		# auto terminate~
	end
	def broadcast msg
		@db[:users].select(:id).each do |e|
			send_msg e[:id], msg
		end
	end
end

if __FILE__ == $PROGRAM_NAME
	m = DBManager.new
	arg = ARGV[0]
	if arg == 'drop'
		m.dropall
	elsif arg == 'msg'		
		DBManager.enter_msgs{|s| m.send_msg ARGV[1], s}
	elsif arg == 'peek'
		m.puts_all_msgs ARGV[1]
	elsif arg == 'broadcast'
		DBManager.enter_msgs{|s| m.broadcast s}
	else
		m.puts_all_users
	end
end
