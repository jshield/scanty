require 'rubygems'
require 'sinatra'
require 'dm-core'
require 'dm-tags'
require 'dm-timestamps'
require 'dm-migrations'
require 'lib/post'
require 'maruku'
require 'builder'
require 'blog.settings'
if Blog.openid_identifier
gem 'ruby-openid', '>=2.1.2'
require 'openid'
require 'openid/store/filesystem'
end

configure do
  enable :sessions
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
		return session[:auth]
	end

	def auth
		stop [ 401, 'Not authorized' ] unless admin?
	end
	
  def logout
    session[:auth] = false
  end
  if Blog.openid_identifier
    def openid_consumer
      @openid_consumer ||= OpenID::Consumer.new(session,
          OpenID::Store::Filesystem.new("#{File.dirname(__FILE__)}/tmp/openid"))  
    end

    def root_url
      request.url.match(/(^.*\/{2}[^\/]*)/)[1]
    end
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

get '/auth/openid' do
  if Blog.openid_identifier
	  erb :auth_openid
	else
	  erb :auth
	end
end

post '/auth' do
	session[:auth] = true if params[:password] == Blog.admin_password
	redirect '/'
end

post '/auth/openid' do
  if Blog.openid_identifier
    openid = params[:openid_identifier]
    begin
      oidreq = openid_consumer.begin(openid)
    rescue OpenID::DiscoveryFailure => why
      "Sorry, we couldn't find your identifier '#{openid}'"
    else
      oidreq.add_extension_arg('sreg','required','nickname')
      oidreq.add_extension_arg('sreg','optional','fullname, email')      
      redirect oidreq.redirect_url(root_url, root_url + "/auth/openid/complete")
    end
  end
end

get '/auth/openid/complete' do
  oidresp = openid_consumer.complete(params, request.url)

  case oidresp.status
    when OpenID::Consumer::FAILURE
      "Sorry, we could not authenticate you with the identifier '{openid}'."

    when OpenID::Consumer::SETUP_NEEDED
      "Immediate request failed - Setup Needed"

    when OpenID::Consumer::CANCEL
      "Login cancelled."

    when OpenID::Consumer::SUCCESS
      if oidresp.display_identifier == Blog.openid_identifier
        session[:auth] = true
        redirect '/' 
      else
        logout
        redirect '/'  
      end  
  end
end

get '/logout' do
  logout
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

