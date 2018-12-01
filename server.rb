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

$pword = "vanilla1"

register do
  def check_Instructor(user)
    condition do
      print(user)
      redirect "/" unless false
    end
  end
end


get '/' do
  File.read(File.join('index.html'))

end

#get '/main.html', :check_Instructor => :user do
get '/main.html' do
  print 'main'
  create_db
  connect_sql
  File.read(File.join('main.html'))
end

get '/vote.html' do
  File.read(File.join('vote.html'))
end

get '/votingResults.html' do
  File.read(File.join('votingResults.html'))
end

post '/uploadVote' do
  mysql = Mysql2::Client.new(:host => 'localhost', :username => 'root', :password => $pword, :database => 'test')

  studentId = params[:id]
  first = params[:first]
  second = params[:second]
  third = params[:third]

  studentId = 'test'

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
        print "failed on 3"
        File.read(File.join('voteFail.html'))
      end
    else
      print "failed on 2"
      File.read(File.join('voteFail.html'))
    end
  else
    print "failed on 1"
    #File.read(File.join('voteFail.html'))
  end
  # TEST----------
  # This is just for ensuring it puts into database
  qry = "INSERT INTO votes (user, vote1, vote2, vote3) VALUES ('" + studentId + "', '" + first + "', '" + second + "', '" + third + "')"
  results = mysql.query(qry)
  print(results)
  File.read(File.join('voteSuccess.html'))
    # -----------------
  end
end

post '/uploadSites' do
  print("Uploading...\n")
  file = params[:file][:tempfile]
  filename = params[:file][:filename]
  File.open(filename, "wb") do |f|
    f.write(file.read)
  end
  Zip::File.open(filename) do |zip_file|
    zip_file.each do |f|
      fpath = File.join("websites\\", f.name)
      zip_file.extract(f, fpath) unless File.exist?(fpath)
    end
  end
  File.delete(filename)
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


post "/login" do
  #make sure username and password provided
  if !(params.has_key?(:username))
    return "NO USERNAME PROVIDED"
  end
  if !(params.has_key?(:password))
    return "NO PASSWORD PROVIDED"
  end
  #check if username is even in database
  mysql = Mysql2::Client.new(:host => 'localhost', :username => 'root', :password => $pword, :database => 'test')
  if(!in_db("salts", "user", params[:username], mysql))
    return "USER NOT FOUND"
  end

  #Getting Salt
  saltquery = "SELECT salt from salts WHERE user = \"" + params[:username] + "\";"
  results = mysql.query(saltquery)
  strResult = get_query(results)

  salt = (query_splitter(strResult))

  #generating password hash
  hashed_pw = Digest::SHA256.hexdigest (params[:password]+salt)

  #getting hash for comparison
  passwordquery = "SELECT pass from userpass WHERE user = \"" + params[:username] + "\";"
  results = mysql.query(passwordquery)
  strResult = query_splitter(get_query(results))

  #Performing comparison with password
  if hashed_pw == strResult
    rolequery = "SELECT role from roles WHERE user = \"" + params[:username] + "\";"
    result = mysql.query(rolequery)
    roleresult = query_splitter(get_query(result))
    if roleresult == 'instructor'
      File.read(File.join('main.html'))
    elsif roleresult == 'ta'
      File.read(File.join('main-ta.html'))
    elsif roleresult == 'student'
      print "is student"
      File.read(File.join('main-student.html'))
    else
      return "Could not find role"
    end
  else
    return "INCORRECT PASSWORD"
  end
end

#function takes query results as string, and returns only value you want
def query_splitter(str)
  return str.split('"')[3]
end

#Takes results of query, and returns it in string form for query splitter
def get_query(results)
  strResult = ""
  results.each do |row|
    strResult = row.to_s
  end
  return strResult
end

not_found do
  '404 NOT FOUND'
end


def connect_sql()
  mysql = Mysql2::Client.new(:host => 'localhost', :username => 'root', :password => $pword, :database => 'test')
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
  db = Mysql2::Client.new(:host => 'localhost', :username => 'root', :password => $pword, :database => 'test')

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

    #Updating salts
    qry = "INSERT INTO salts (user, salt) VALUES ('" + row[0] + "', '" + salt + "')"
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



