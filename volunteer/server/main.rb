#!/usr/bin/env ruby
require 'sinatra'
require 'json'
load 'db_manager.rb'

set :port, 8888
set :bind, '0.0.0.0'

Manager = DBManager.new
DataPath = "data"

get '/profile/:id' do
	userid = params[:id]
	user = Manager.get_by_id(userid)
	unless user
		user = Manager.create_user userid # return blank user (or {} if id used)
	end
	Manager.read_all_msgs userid
	JSON.generate user 
end
post '/upload/:id' do
	userid = params[:id]
	emo = params[:emo].to_sym  # A Symbol
	user = Manager.get_by_id(userid)
	ext = params[:file][:filename].split(".")[1]
	begin
		File.open([DataPath, emo, userid+"_"+user[emo]+ext].join "/", "w") do |f|
			f.write(params[:file][:tempfile].read)
		end
		Manager.set_emo_count userid, emo, user[emo]
		"OK"
	rescue
		"OOOPS"
	end
end
