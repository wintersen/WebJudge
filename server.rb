require 'sinatra'
require 'mysql2'
require 'sinatra/reloader' if development?
# password to sql marcoserika
# #mysql 5.7 from official wesite
# #connection succeeded
# #NOTE IF TESTING, REPLACE WITH YOUR OWN USER/PASS/INFO
get '/' do
  File.read(File.join('index.html'))

end

get '/main.html' do
  print 'main'
  File.read(File.join('main.html'))
  print connect_sql
end

not_found do
  '404 NOT FOUND'
end


def connect_sql()
  #db = Mysql2.connect('localhost', 'marcos', 'H@ha12345', 'db1')
  mysql = Mysql2::Client.new(:host => 'localhost', :username => 'root', :password => 'H@ha12345')
  '\nSuccess\n'
end