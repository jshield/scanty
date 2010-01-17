require 'rubygems'
require 'sinatra'
require 'dm-core'
require 'dm-tags'
require 'dm-timestamps'
require 'lib/post'
require 'maruku'
require 'builder'
require 'blog.settings'

configure do
	DataMapper.setup(:default, ENV['DATABASE_URL'] || 'sqlite3:./blog.db')
  DataMapper.auto_upgrade!
end

error do
	e = request.env['sinatra.error']
	puts e.to_s
	puts e.backtrace.join("\n")
	"Application error"
end

helpers do
	def admin?
		request.cookies[Blog.admin_cookie_key] == Blog.admin_cookie_value
	end

	def auth
		stop [ 401, 'Not authorized' ] unless admin?
	end
end

layout 'layout'

### Public

get '/' do
	@posts = Post.last(10)
	erb :index, :layout => false
end

get '/past/:year/:month/:day/:slug/' do
	@post = Post.first(:slug => params[:slug])
	stop [ 404, "Page not found" ] unless @post
	@title = @post.title
	erb :post
end

get '/past/:year/:month/:day/:slug' do
	redirect "/past/#{params[:year]}/#{params[:month]}/#{params[:day]}/#{params[:slug]}/", 301
end

get '/past' do
	@posts = Post.reverse
	@title = "Archive"
	erb :archive
end

get '/past/tags/:tag' do
	@tag = params[:tag]
	@posts = Post.tagged_with(@tag).reverse
	@title = "Posts tagged #{@tag}"
	erb :tagged
end

get '/feed' do
	@posts = Post.last(20)
	content_type 'application/atom+xml', :charset => 'utf-8'
	builder :feed
end

get '/rss' do
	redirect '/feed', 301
end

### Admin

get '/auth' do
	erb :auth
end

post '/auth' do
	set_cookie(Blog.admin_cookie_key, Blog.admin_cookie_value) if params[:password] == Blog.admin_password
	redirect '/'
end

get '/posts/new' do
	auth	
	erb :new
end

post '/posts' do
	auth
	post = Post.create(:title => params[:title], :body => params[:body], :slug => Post.make_slug(params[:title]))
	post.tag_list = params[:tags]
	post.save
	redirect post.url
end

get '/past/:year/:month/:day/:slug/edit' do
	auth
	@post = Post.first(:slug => params[:slug])
	stop [ 404, "Page not found" ] unless @post
	erb :edit
end

post '/past/:year/:month/:day/:slug/' do
	auth
	post = Post.first(:slug => params[:slug])
	stop [ 404, "Page not found" ] unless post
	post.title = params[:title]
	post.tag_list = params[:tags]
	post.body = params[:body]
	post.save
	redirect post.url
end

