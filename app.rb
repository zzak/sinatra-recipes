require 'sinatra'
require 'sass'
require 'json'
require 'open-uri'
require 'slim'
require 'glorify'

set :public_folder, File.dirname(__FILE__) + '/public'
configure :production do
  sha1, date = `git log HEAD~1..HEAD --pretty=format:%h^%ci`.strip.split('^')

  require 'rack/cache'
  use Rack::Cache

  before do
    cache_control :public, :must_revalidate, :max_age=>300
    etag sha1
    last_modified date
  end
end

Tilt.prefer Sinatra::Glorify::Template
set :markdown, :layout_engine => :slim
set :views, File.dirname(__FILE__)
set :ignored_dirs, %w[tmp log config public bin]

before do
  @toc = toc
  @menu = Dir.glob("./*/").map do |file|
    next if settings.ignored_dirs.any? {|ignore| /#{ignore}/i =~ file}
    file.split('/')[1]
  end.compact.sort
end

helpers do
  def toc
    temp = Dir.glob("./**/*.md").map {|path| path[2..-1].split("/") }.group_by do |folder, md|
      folder
    end
    # remove duplicates and flatten the values array
    temp.update(temp) do |folder, file|
      file = (file.flatten.uniq - [folder]).map do |f|
        f[0...-3]
      end
    end 
  end
end

get '/' do
  begin
    open("https://api.github.com/repos/sinatra/sinatra-recipes/contributors") do |api|
      @contributors = JSON.parse(api.read)
    end 
  rescue SocketError => e
  end
  markdown :README
end

get '/p/:topic' do
  pass if params[:topic] == '..'
  @readme = true
  @children = Dir.glob("./#{params[:topic]}/*.md").map do |file|
    next if file =~ /README/
    next if file.empty? or file.nil?
    file.split('/')[-1].sub(/\.md$/, '')
  end.compact.sort
  markdown :"#{params[:topic]}/README"
end

get '/p/:topic/:article' do
  pass if params[:topic] == '..'
  markdown :"#{params[:topic]}/#{params[:article]}"
end

get '/style.css' do
  sass :style
end

__END__

@@ layout
doctype 5
html
  head
    meta charset="utf-8"
    meta content="IE=edge,chrome=1" http-equiv="X-UA-Compatible"
    meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1, user-scalable=no"
    title Sinatra Recipes
    link rel="stylesheet" type="text/css" href="/stylesheets/normalize.css"
    link rel="stylesheet" type="text/css" href="/style.css"
    link rel="stylesheet" type="text/css" href="/stylesheets/pygment_trac.css"
    link rel="stylesheet" type="text/css" href="/stylesheets/chosen.css"
    link rel="shortcut icon" href="https://github.com/sinatra/resources/raw/master/logo/favicon.ico"
    script src="/javascripts/scale.fix.js"
    script src="https://ajax.googleapis.com/ajax/libs/jquery/1.5.1/jquery.min.js"
    script src="/javascripts/chosen.jquery.min.js"

  body
    a name="top"
    .wrapper
      #header
        a href="/"
          #logo
            img id="logo" src="https://github.com/sinatra/resources/raw/master/logo/sinatra-classic-156.png"
          #logoname
            h1 Sinatra Recipes
            h2 Community contributed recipes and techniques
              
      div.clear

      #content
        #post
          == yield
      #toc
        - if @toc
          dl
            - @toc.each do |k,v|
              dh 
                a href="/p/#{k.to_sym}"
                  == k.capitalize.sub('_', ' ')
              - v.each do |value|
                dd 
                  a href="/p/#{k.to_sym}/#{value}?#article"
                    == value.capitalize.sub('_', ' ')
                
        - if @children
          ul
            - @children.each do |child|
              li
                a href="/p/#{params[:topic]}/#{child}?#article"
                  == child.capitalize.sub('_', ' ')
       
      #footer
        - if @readme
          h2 Did we miss something?
          p
           | It's very possible we've left something out, that's why we need your help!
           | This is a community driven project after all. Feel free to fork the project 
           | and send us a pull request to get your recipe or tutorial included in the book. 
          p 
           | See the <a href="http://github.com/sinatra/sinatra-recipes#readme">README</a> 
           | for more details.
        - if @contributors
          #contributors
            h2 Contributors
            p 
              | These recipes are provided by the following outsanding members of the Sinatra 
              | community:
            dl id="contributors"
              - @contributors.each do |contributor|
                dt 
                  a href="http://github.com/#{contributor["login"]}"
                    img src="http://www.gravatar.com/avatar/#{contributor["gravatar_id"]}?s=50"

@@ style
body
  font-family: 'Lucida Grande', Verdana, sans-serif
  margin: 0 auto
  padding: 0 10px
  max-width: 800px
  font-size: 0.85em
  line-height: 1.5em

h1, h2, h3, h4, h5
  font-family: Georgia, 'bitstream vera serif', serif
  font-weight: normal
  font-size: 2em
  margin: 50px 0px 20px
  line-height: 1.15em

pre, code, tt
  padding: 10px
  overflow: visible
  overflow-Y: hidden
  background: #F6F6F6
  font-family: Monaco, monospace
  font-size: 0.9em

code, tt
  padding: 3px

a:link, a:visited
  color: #3F3F3F

a:hover, a:active
  color: #8F8F8F

.small
  font-size: .7em

#header
  margin: 30px 0px
  
  a
    float: left
    text-decoration: none
    overflow: hidden
    
  #logo
    width: 100px
    float: left
    margin: 0 15px 0 0
  #logoname
    float: right
    margin-top: 15px 
  h1
    font-size: 2.65em
    margin: 0 0
  h2
    font-style: oblique
    font-size: 1em
    margin: 10px 0 0 0
  nav
    float: right
    width: 100%

.clear
  clear: both

#contributors dt
  display: inline-block


#children
  clear: both
  ul li
    float: left
    width: 275px
    height: 40px

#content
  margin-top: 30px
  width: 60%
  float: left

#toc
  float: left
  margin-top: 80px
  width: 30%
  font-size: 0.9em
  padding-left: 50px

#footer
  float: left
  margin-top: 20px
  width: 60%
