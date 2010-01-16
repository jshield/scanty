require 'rubygems'
require 'spec'
require 'dm-core'
require 'dm-tags'
require 'dm-timestamps'

DataMapper.setup(:default,'sqlite3::memory:')

$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib')
require 'post'

require 'ostruct'
Blog = OpenStruct.new(
	:title => 'My blog',
	:author => 'Anonymous Coward',
	:url_base => 'http://blog.example.com/'
)
