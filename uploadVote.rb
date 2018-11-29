require 'dm-core'
require 'dm-migrations'

DataMapper.setup()

class Vote
  include DataMapper::Resource

  property :id, Serial
  property :name,
end