require 'sinatra'
require 'mysql2'
require 'csv'
#require 'sinatra/reloader' if development?
require 'digest'
require 'securerandom'
require 'zip'
# password to sql marcoserika
# #mysql 5.7 from official wesite
# #connection succeeded
# #NOTE IF TESTING, REPLACE WITH YOUR OWN USER/PASS/INFO

enable :sessions

get '/' do
  File.read(File.join('index.html'))

end

get '/main.html' do
  print 'main'
  create_db
  connect_sql
  File.read(File.join('main.html'))
end

get '/vote.html' do
  File.read(File.join('vote.html'))
end

post '/uploadVote' do
  mysql = Mysql2::Client.new(:host => 'localhost', :username => 'root', :password => 'vanilla1', :database => 'test')

  studentId = params[:id]
  first = params[:first]
  second = params[:second]
  third = params[:third]

  # student has already voted
  if(in_db('votes', 'user', studentId, mysql))
    File.read(File.join('voteRepeat.html'))
  else
  # check values
  if(in_db('websites', 'user', first, mysql))
    if(in_db('websites', 'user', second, mysql))
      if(in_db('websites', 'user', third, mysql))
        # insert result into db
        qry = "INSERT INTO votes (user, vote) VALUES ('" + studentId + "', '" + first + "', '" + second + "', '" + third + "')"
        results = mysql.query(qry)
        print(results)
        File.read(File.join('voteSuccess.html'))
      else
        File.read(File.join('voteFail.html'))
      end
    else
      File.read(File.join('voteFail.html'))
    end
  else
    File.read(File.join('voteFail.html'))
  end

  end
end

post '/uploadSites' do
  tempfile = params[:file][:tempfile]
  filename = params[:file][:filename]

  Zip::File.open(filename) do |zip_file|
    zip_file.each do |f|
      fpath = File.join("websites\\", f.name)
      zip_file.extract(f, fpath) unless File.exist?(fpath)
    end
  end
  "Upload Complete"
end



post '/uploadCsv' do
  # https://stackoverflow.com/questions/2521053/how-to-read-a-user-uploaded-file-without-saving-it-to-the-database
  file_data = params[:classCsv]
  if file_data.respond_to?(:read)
    csvdata = file_data.read
  elsif file_data.respond_to?(:path)
    csvdata = File.read(file_data.path)
  else
    logger.error "Bad file_data: #{file_data.class.name}: #{file_data.inspect}"
  end
  #call function to handle csv here with csvdata
end

not_found do
  '404 NOT FOUND'
end


def connect_sql()
  mysql = Mysql2::Client.new(:host => 'localhost', :username => 'root', :password => 'vanilla1', :database => 'test')
  results = mysql.query("SELECT * FROM userpass")
  results.each do |row|
    print("\n"+(row.to_s))
  end

end

def in_db(table, column, value, connection)
  qry = "SELECT EXISTS (SELECT * FROM "+table+" WHERE "+column+" = '" + value +"')"
  results = connection.query(qry)
  results.each do |row|
    if row.to_s.include? "=>1"
      return true
    end
  end
  return false
end

def create_db()
  #connect to db first
  db = Mysql2::Client.new(:host => 'localhost', :username => 'root', :password => 'vanilla1', :database => 'test')

  #Read csv for data to fill the dbs
  CSV.foreach("information.csv") do |row|
    if in_db("userpass", "user", row[0], db)
      print("\nCONTINUING\n")
      next
    end
    #updating usernames and passwords table
    pw, salt = get_hash(row[1])
    qry = "INSERT INTO userpass (user, pass) VALUES ('" + row[0] + "', '" + pw + "')"
    results = db.query(qry)
    print(results)

    #updating roles table
    qry = "INSERT INTO roles (user, role) VALUES ('" + row[0] + "', '" + row[2] + "')"
    results = db.query(qry)
    print(results)
  end
end

def get_hash(password)
  #Credit to owasp website hashing guide
  salt = SecureRandom.hex
  hashed_pw = Digest::SHA256.hexdigest (password+salt)
  return hashed_pw, salt
end


