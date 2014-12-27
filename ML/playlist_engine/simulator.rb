#!/usr/bin/env ruby
HAPPY = 0
ANGRY = 1
SAD = 2
JOYFUL = 3

class PlayListEngine
	def initialize emo, list
		@emo = emo
		@n = list.length
		@rate_sum = 0.0
		@musics = list.collect do |e| 
			@rate_sum += e[:rate]
			Music.new(e[:path], e[:rate], @n)
		end
		add_2_playlist get_next_song
		@cur_i = 0
		play
	end
	def add_2_playlist music
		@play_list ||= []
		@good_job_list ||= []
		@play_list.push music
		@good_job_list.push false
	end
	#playlist sysstem
	#### mini ML goes here
	def get_next_song
		tar = nil
		r = rand()*@rate_sum
		ok = false
		@musics.each do |music|
			if ok
				@rate_sum += music.inc
			else
				r -= music.cur_rate
				if r < 0
					@rate_sum += music.choose
					tar = music
					ok = true
				else
					@rate_sum += music.inc
				end
			end
		end
		tar = @musics.last if tar == nil
		tar
	end
	####
	def next_song
		@cur_i += 1
		add_2_playlist get_next_song if @cur_i == @play_list.length
		play
	end
	def prev_song
		if @cur_i == 0
			@cur_i = @play_list.length - 1
			raise Exception.new "It's already the first song!"
		else
			@cur_i -= 1
		end
		play
	end
	#depends on android
	def play
		s = ""
		@musics.each_with_index do |m, i|
			s += m==@play_list[@cur_i] ? "\033[31m("+m.name + ", #{m.cur_rate})\033[m " : "("+m.name + ", #{m.cur_rate};) "
		end
		puts s
	end
	# reward system
	def reward music
		sum = 0
		@musics.each {|m| sum += m.punish(@n) if m != music}
		music.reward sum, @n
		save
	end
	def good_job
		if @good_job_list[@cur_i]
			raise Exception.new "U've just rate it!"
		else
			@good_job_list[@cur_i] = true
			reward @play_list[@cur_i]
		end
	end
	def survives_9_secs
		reward @play_list[@cur_i]
		next_song
	end
	def jump_song i
		@cur_i = @play_list.length
		@rate_sum += @musics[i].choose
		add_2_playlist @musics[i]
		good_job
		play
	end
	def add_new_songs *paths
		rate = @n
		if paths.last.class == false #check if local
			rate = @n**2
			paths.pop
		end
		paths.each do |path|
			@musics.push Music.new path, rate, @n  # 平方？
		end
		save @musics[(@musics.length-paths.length)...@musics.length]
	end
	#file system, related with @emo
	def save musics=nil
		if musics
			puts musics
		else 
			save @musics
		end
	end
end

class Music
	def initialize path, rate, n
		@rate = @cur_rate = rate
		@step = rate*1.0/n
		@path = path
	end
	#playlist system
	def inc
		@cur_rate += @step
		@step
	end
	def choose
		tmp = @cur_rate
		@cur_rate = 0
		-tmp
	end
	def rate #debug usage
		@rate
	end
	def cur_rate
		@cur_rate
	end
	def name
		@path.split("/").last
	end
	#reward system, won't change rate_sum
	def punish n
		tmp = @step
		@rate -= @step
		@step = 1.0*@rate / n
		tmp
	end 
	def reward r, n
		@rate += r
		@step = @rate / n
	end
	#file system
	def to_s
		"path => {#@path}, rate => {#@rate}"
	end
end


#a = [{:rate=>16, :path=>"123/test1.mp3"}, {:rate=>16, :path=>"123/test2.mp3"}, {:rate=>16, :path=>"123/test3.mp3"}, {:rate=>16, :path=>"123/test4.mp3"}]
a = (1..10).collect { |e| {:path=>"music/track #{e}", :rate=>80}}
engine = PlayListEngine.new ANGRY, a
n = 11
while true
	s = STDIN.readline
	s = s.split("\n")[0]
	if s == "p"
		begin
			engine.prev_song
		rescue Exception => e
			puts e
		end
	elsif s == "g"
		begin
			engine.good_job
		rescue Exception => e
			puts e
		end
	elsif s == "v"
		engine.survived_5_secs
	elsif s == "s"
		engine.save
	elsif s == "a"
		engine.add_new_songs "new_music/new #{n}", true
		n += 1
	else
		i = s.to_i
		if i == 0
			engine.next_song
		else
			engine.jump_song i-1
		end
	end
end
