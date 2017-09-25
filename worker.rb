require 'net/http'
require 'json'
require 'streamio-ffmpeg'

converted_videos = []
ignored_files = %w[. ..]

base_path = '/home/ubuntu/uploads/video'
original_video_path = "#{base_path}/original_video"
video_path = "#{base_path}/video"

Dir.mkdir(original_video_path) unless Dir.exist?(original_video_path)
Dir.mkdir(video_path) unless Dir.exist?(video_path)
Dir.new(original_video_path).each do |movie_folder|
  next if ignored_files.include?(movie_folder) || movie_folder.include?('CONVERTED')
  Dir.new("#{original_video_path}/#{movie_folder}").each do |movie_path|
    next if ignored_files.include?(movie_path)
    converted_folder_path = "#{video_path}/#{movie_folder}"
    Dir.mkdir(converted_folder_path) unless Dir.exist?(converted_folder_path)
    movie_file = File.new("#{converted_folder_path}/#{movie_folder}.mp4", 'w')
    movie = FFMPEG::Movie.new("#{original_video_path}/#{movie_folder}/#{movie_path}")
    movie.transcode(movie_file.path)
    converted_videos << movie_folder
    File.rename("#{original_video_path}/#{movie_folder}", "#{original_video_path}/#{movie_folder}")
  end
end

unless converted_videos.empty?
  uri = URI.parse('http://ec2-34-229-67-157.compute-1.amazonaws.com/contests/videos_transcoded')
  header = {'Content-Type' => 'text/json'}
  videos = {videos: converted_videos}
  http = Net::HTTP.new(uri.host, uri.port)
  request = Net::HTTP::Post.new(uri.request_uri, header)
  request.body = videos.to_json
  http.request(request)
end
