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
		@db.create_table? :su_relationships do
			String :userid
			Integer :sid
		end
		@users = @db[:users]
		@messages = @db[:messages]
		@sentences = @db[:sentences]
		@su_rs = @db[:su_relationships]
		create_user "woodyyo5566" unless get_by_id "woodyyo5566"  # create super user
	end
	def user_count
		@users.count
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
	def get_all_users
		@users.all
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
	def get_sentence emo, userid
		emo = LIST.find_index emo
		s = @sentences.where('count < 3 and emo=?', emo).first
		if s
			@sentences.where(:id => s[:id]).update(:count => s[:count]+1)
			@su_rs.insert(:sid => s[:id], :userid => userid)
			s[:sentence]
		else
			''
		end
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
end

