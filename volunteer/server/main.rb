#!/usr/bin/env ruby
require 'sinatra'
require 'json'
require 'haml'
load 'db_manager.rb'

set :port, 8799 # project go go XDD
set :bind, '0.0.0.0'

Manager = DBManager.new
DataPath = "data"

get "/" do
	haml  :"index"
end
post '/create' do
	begin
		id = params[:id]
		user = Manager.create_user id # return blank user
		msg = "安安，#{id}，歡迎成為小白鼠#{Manager.user_count}號！"
		user[:msgs] = [msg]
		JSON.generate user
	rescue => e  # ID Used or Illegal
		e.to_s
	end
end
get '/profile/:id' do
	userid = params[:id]
	user = Manager.get_by_id(userid)
	if user
		Manager.read_all_msgs userid
		JSON.generate user 
	else
		"user #{userid} not found!"
	end
end
get '/sentence/:userid/:emo' do # 拿單一句子，也就是手機端做的事
	emo = params[:emo]
	userid = params[:userid]
	Manager.get_sentence emo, userid # return '' if no sentence
end
get '/sentences/:emo' do # web version, 拿所有句子，附贈上傳表格
	@emo = params[:emo]
	@a = Manager.get_sentences @emo
	haml :"sentences"
end
get '/sentences' do
	@emo = "總覽"
	@a = []
	haml :"sentences"
end
post '/sentences/:emo' do
	@emo = params[:emo]
	s = params[:sentence]
	Manager.add_sentence s, @emo
	@a = Manager.get_sentences @emo
	haml :"sentences"
end
post '/upload/:emo' do
	emo = params[:emo].to_sym  # A Symbol
	ext = params[:file][:filename].split(".").last
	userid = params[:file][:filename].split("_")[0..-2].join("_")
	num = params[:file][:filename].split("_").last.to_i
	filepath = [DataPath, emo, userid+"_"+num.to_s+"."+ext].join "/";
	begin
		File.open(filepath, "w") do |f|
			f.write(params[:file][:tempfile].read)
			puts params[:file][:tempfile].read
		end
		Manager.set_emo_count userid, emo, num
		"Y"
		File.open("log/#{userid}", "a") do |f|
			f.write "#{Time.now} -> #{emo}\n"
		end
	rescue => e
		puts e
		puts "========================="
		"N"
	end
end
get '/readme' do
	haml :"readme"
end
get '/apk-file' do
	File.open("download.log", "a") do |f|
		f.write "#{request.ip} #{Time.now}\n"
	end
	redirect "/app-release.apk", 303
end
