require 'ostruct'
Blog = OpenStruct.new(
    :title => 'a scanty blog',
    :author => 'John Doe',
    :url_base => 'http://localhost:4567/',
    :admin_password => 'changeme',
    :openid_identifier => nil,
    :admin_cookie_key => 'scanty_admin',
    :admin_cookie_value => '51d6d976913ace58',
		:disqus_shortname => nil,
		:add_this => nil
)
