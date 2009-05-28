require 'rubygems'
require 'open-uri'
require 'xmlrpc/client'

WordPressSite = "http://SITE.wordpress.com"
WordPressUsername = 'username'
WordPressPassword = 'password'

PosterousApi = 'http://posterous.com/api'
PosterousEmail = 'email'
PosterousPassword = 'password'

MaxPosts = 100000

def posts_from_wordpress
  server = XMLRPC::Client.new2("#{WordPressSite}/xmlrpc.php")

  result = server.call("wp.getUsersBlogs", WordPressUsername, WordPressPassword)

  blogid = result[0]['blogid']
  result = server.call("metaWeblog.getRecentPosts", blogid, WordPressUsername, WordPressPassword, MaxPosts)

  posts = []
  result.each do |post| 
    if post['post_status'] == 'publish'
      posts << posterous_post_params(post)
    end
  end

  posts
end

def posterous_post_params wp_post
  post = { 
    'title' => wp_post['title'],
    'body' => wp_post['description'],
    'tags' => wp_post['categories'].delete_if {|tag| tag.eql? 'all'}.join(','),
    'date' => wp_post['dateCreated'].to_time.utc.to_s
  }

  post
end

def get_posterous_site_id
  #url = URI.parse("#{PosterousApi}/getsites")
  #req = Net::HTTP::Get.new(url.path)
  #req.basic_auth PosterousEmail, PosterousPassword
  #res = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
  #res.body

  # TODO: Should actually parse this list and get the site_id
  # Right now I just return a site id by hand cause I'm a lazy fuck.
  '111111' # XXX: Change this to YOUR site_id
end

def publish_to_posterous posts
  posts.each do |post|
    post['site_id'] = get_posterous_site_id

    url = URI.parse("#{PosterousApi}/newpost")
    req = Net::HTTP::Post.new(url.path)
    req.basic_auth PosterousEmail, PosterousPassword
    req.set_form_data post
    res = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }

    puts res.body

    sleep 1
  end
end

publish_to_posterous posts_from_wordpress
