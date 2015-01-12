#!/usr/bin/env ruby
require 'sequel'
load 'db_manager.rb'

class DBManager
	#### Admin's POWER ####
	def dropall
		puts "If u r sure to do this, please enter the project's name"
		s = STDIN.readline.split("\n")[0]
		if s == "Dj. Right"
			puts "Got it, master~"
			@db.drop_table :users
			@db.drop_table :messages
			@db.drop_table :su_relationships
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
	def rm_sentence s_id
		@sentences.where(:id => s_id).delete
	end
	def refresh_sentences
		@sentences.update(:count => 0)
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
		#elsif arg == 'adds'
		#DBManager.enter_msgs{|s| m.add_sentence s, ARGV[1]}
	elsif arg == 'rmsentence'
		m.rm_sentence ARGV[1].to_i
	elsif arg == 'refresh'
		m.refresh_sentences
	elsif arg == 'commands'
		puts 'drop'
		puts 'msg'
		puts 'peek'
		puts 'broadcast'
		puts 'sentences'
		puts 'rmsentence'
		puts 'refresh'
	elsif arg == 'completions'
		if ['msg', 'peek'].include? ARGV[1]
			m.get_all_users.each do |e|
				puts e[:id]
			end
		end
	else
		puts m.get_all_users
	end
end
