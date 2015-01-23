# -*-  -*-
require 'sequel'

LIST = ["happy", "angry", "sad", "joyful"]

class DBManager
	def initialize
		@db = Sequel.sqlite('v_server.db')
		@db.create_table? :users do
			String :userid, :unique => true, :null => false
			Integer :angry, :default => 0
			Integer :sad, :default => 0
			Integer :happy, :default => 0
			Integer :joyful, :default => 0
		end
		@db.create_table? :messages do
			String :mid
			Text :body
			DateTime :time
			FalseClass :read, :default => false
		end
		@db.create_table? :sentences do
			primary_key :sid
			String :sentence, :unique => true
			Integer :emo
			Integer :count, :default => 0
		end
		@db.create_table? :su_relationships do
			String :userid
			Integer :sid
		end
		@users = @db[:users]
		@messages = @db[:messages]
		@sentences = @db[:sentences]
		@su_rs = @db[:su_relationships]
		create_user "admin5566" unless get_by_id "admin5566"  # create super user
	end
	def user_count
		@users.count
	end
	def create_user id
		if id =~ / |\n/i or id.length < 2 or id =~ /\?/i
			raise ArgumentError, 'ID Illegal'
		end
		begin
			@users.insert(:userid => id)
			{:userid => id, :angry => 0, :sad => 0, :joyful => 0, :happy => 0, :msgs => []}
		rescue => e
			puts e
			raise ArgumentError, 'ID Used'
		end
	end
	def get_by_id userid
		user = @users.where(:userid => userid).first
		user[:msgs] = get_all_msgs(userid) if user
		user
	end
	def get_all_users
		@users.all
	end
	def send_msg userid, msg
		if get_by_id userid
			@messages.insert(:mid => userid, :body => msg, :time => Time.now)
			true
		else
			false
		end
	end
	def get_all_msgs userid  # only return msgs' body. Setting the flag or not is the server's business!
		msgs = @messages.select(:body).where(:mid => userid, :read => false).all
		msgs.collect { |e| e[:body] }
	end
	def read_all_msgs userid  # only set the flag to true
		@messages.where(:mid => userid, :read => false).update(:read => true)
	end
	def set_emo_count userid, emo, count
		@users.where(:userid => userid).update(emo => count)
	end
	def get_sentence emo, userid
		emo = LIST.find_index emo
		s = nil
		@sentences.where('count < 5 and emo=?', emo).each do |sentence|
			if @su_rs.where(:sid => sentence[:sid], :userid => userid).count == 0
				s = sentence
				break
			end
		end
		if s
			@sentences.where(:sid => s[:sid]).update(:count => s[:count]+1)
			@su_rs.insert(:sid => s[:sid], :userid => userid)
			s[:sentence]
		else
			''
		end
	end
	def get_sentences emo
		emo = LIST.find_index emo
		@sentences.select(:sentence).where('count < 5 and emo=?', emo).collect do |e|
			e[:sentence]
		end
	end
	def add_sentence s, emo
		emo = LIST.find_index emo
		begin
			@sentences.insert(:sentence => s, :emo => emo)
		rescue Sequel::UniqueConstraintViolation => e
			puts e
		end
	end
end
