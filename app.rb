require 'thin'
require 'http_router'
require 'rack/websocket'
require 'rack'

$port = ENV['PORT'].to_i


class SocketApp < Rack::WebSocket::Application
  @@clients = []

  def on_open(env)
    $stderr.puts 'on_open'

    @@clients << self
    id = @@clients.size
    @@clients.each { |e| e.send_data "<#{ id }> joins the chat." }
  end

  def on_close(env)
    $stderr.puts 'on_close'
    id = @@clients.find_index(self) + 1
    @@clients.each { |e| e.send_data "<#{ id }> leaves the chat." }
  end

  def on_message(env, message)
    $stderr.puts "on_message:: |#{ message }|"
    @@clients.each { |e| e.send_data message }
  end
end


class WebApp
  def call(env)
    [ 200, { 'Content-Type' => 'text/html' }, open('index.html').read ]
  end
end


app = HttpRouter.new do
  add('/socket').to SocketApp.new
  add('/').to WebApp.new
end


Rack::Handler::Thin.run app, Port: $port
