require File.expand_path('../server/web_socket_server', __FILE__)

wss = WebSocketServer.new
wss.on('server_started') do |event|
  # event Event
  # event.data = {:started_at, :server=>{:ip,:port}}
end
wss.on('connect') do |event|
  ws = event.data[:web_socket]
  ws.send('test')
end
wss.on('receive') do |event|
  cp event.data[:message]
  ws = event.data[:web_socket]
  ws.send('test')
end

def sp(msg)
  if msg.respond_to?(:each_line) && msg.count($/)>1
    msg.each_line { |l| print '[WS]: '+l }
  else
    print '[WS]: '+msg.inspect+$/
  end

end

def cp(msg)
  print '[Client]: '+msg.inspect+$/
end

wss.start('127.0.0.1', 332)