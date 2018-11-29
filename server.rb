require 'sinatra'
require 'mysql2'
require 'csv'
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
  create_db
  connect_sql
  File.read(File.join('main.html'))
end

not_found do
  '404 NOT FOUND'
end


def connect_sql()
  print("")
  #db = Mysql2.connect('localhost', 'marcos', 'H@ha12345', 'db1')
  mysql = Mysql2::Client.new(:host => 'localhost', :username => 'root', :password => 'H@ha12345', :database => 'test')
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
  db = Mysql2::Client.new(:host => 'localhost', :username => 'root', :password => 'H@ha12345', :database => 'test')

  #Read csv for data to fill the dbs
  CSV.foreach("information.csv") do |row|
    if in_db("userpass", "user", row[0], db)
      print("\nCONTINUING\n")
      next
    end
    #updating usernames and passwords table
    qry = "INSERT INTO userpass (user, pass) VALUES ('" + row[0] + "', '" + row[1] + "')"
    results = db.query(qry)
    print(results)

    #updating roles table
    qry = "INSERT INTO roles (user, role) VALUES ('" + row[0] + "', '" + row[2] + "')"
    results = db.query(qry)
    print(results)
  end
end
