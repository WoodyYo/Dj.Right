#!/usr/bin/env ruby
require 'sequel'

LIST = ["happy", "angry", "sad", "joyful"]

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
		@db.create_table? :sentences do
			primary_key :id
			String :sentence, :unique => true
			Integer :emo
			Integer :count, :default => 0
		end
		@users = @db[:users]
		@messages = @db[:messages]
		@sentences = @db[:sentences]
		create_user "woodyyo5566" unless get_by_id "woodyyo5566"  # create super user
	end
	def create_user id
		if id =~ / |\n/i
			raise ArgumentError, 'ID Illegal'
		end
		begin
			@users.insert(:id => id)
			{:id => id, :angry => 0, :sad => 0, :joyful => 0, :happy => 0, :msgs => []}
		rescue => e
			puts e
			raise ArgumentError, 'ID Used'
		end
	end
	def get_by_id userid
		user = @users.where(:id => userid).first
		user[:msgs] = get_all_msgs(userid) if user
		user
	end
	def puts_all_users
		puts @users.all
	end
	def send_msg userid, msg
		if get_by_id userid
			@messages.insert(:id => userid, :body => msg, :time => Time.now)
			true
		else
			false
		end
	end
	def get_all_msgs userid  # only return msgs' body. Setting the flag or not is the server's business!
		msgs = @messages.select(:body).where(:id => userid, :read => false).all
		msgs.collect { |e| e[:body] }
	end
	def read_all_msgs userid  # only set the flag to true
		@messages.where(:id => userid, :read => false).update(:read => true)
	end
	def set_emo_count userid, emo, count
		@users.where(:id => userid).update(emo => count)
	end
	def get_sentence emo
		emo = LIST.find_index emo
		s = @sentences.where('count < 3 and emo=?', emo).first
		@sentences.where(:id => s[:id]).update(:count => s[:count]+1)
		s ? s[:sentence] : ''
	end
	def get_sentences emo
		emo = LIST.find_index emo
		@sentences.select(:sentence).where('count < 3 and emo=?', emo).collect do |e|
			e[:sentence]
		end
	end
	def add_sentence s, emo
		emo = LIST.find_index emo
		@sentences.insert(:sentence => s, :emo => emo)
	end
	#### ROOT's POWER ####
	def dropall
		puts "If u r sure to do this, please enter the project's name"
		s = STDIN.readline.split("\n")[0]
		if s == "Dj. Right"
			puts "Got it, master~"
			@db.drop_table :users
			@db.drop_table :messages
			@db.drop_table :sentences
		else
			puts "Screw u"
		end
	end
	def puts_all_msgs userid
		@messages.where(:id => userid).each { |e| puts e }
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
		@users.select(:id).each do |e|
			send_msg e[:id], msg
		end
	end
	def puts_all_sentences
		@sentences.each {|e| puts e}
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
	elsif arg == 'sentences'
		m.puts_all_sentences
	elsif arg == 'adds'
		DBManager.enter_msgs{|s| m.add_sentence s, ARGV[1]}
	else
		m.puts_all_users
	end
end
