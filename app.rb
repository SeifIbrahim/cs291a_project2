require 'digest'
require 'sinatra'
require 'google/cloud/storage'

MEGABYTE = 1024.0 * 1024.0

storage = Google::Cloud::Storage.new(project_id: 'cs291a')
bucket = storage.bucket 'cs291project2', skip_lookup: true

def valid_files(bucket)
  files = bucket.files
  paths = files.all.map do |f|
    f.name.to_s
  end
  valid_paths = paths.select { |s| s[2] == '/' && s[5] == '/' }
  # convert to lower case, remove slashes, and ensure 64 characters
  valid_paths.map do |s|
    s.tr!('/', '').to_s.downcase
  end.select { |s2| s2.length == 64 }
end

get '/' do
  redirect '/files/', 302
end

get '/files/' do
  [200, { 'Content-Type' => 'application/json' }, valid_files.sort.to_json]
end

post '/files/' do
  # ensure the file param is passed
  halt 422 unless params[:file]
  tempfile = params[:file][:tempfile]

  # ensure the file is at most 1 megabyte
  halt 422 unless tempfile.size <= MEGABYTE
  hash = Digest::SHA256.hexdigest(tempfile.read)

  # ensure a file with the same name hasn't been uploaded
  PP.pp valid_files(bucket)
  halt 409 if valid_files(bucket).include? hash

  # store the file
  bucket_path = hash[0..1] + '/' + hash[2..3] + '/' + hash[4..-1]
  PP.pp bucket_path
  bucket.create_file(tempfile.path, bucket_path)

  [200, { 'Content-Type' => 'application/json' }, { uploaded: hash }.to_json]
end

get '/files/:file' do
end

delete '/files/:file' do
end
