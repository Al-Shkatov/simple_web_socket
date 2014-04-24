require 'socket'
require File.expand_path('../web_socket', __FILE__)
require File.expand_path('../../libs/evt/event', __FILE__)
require File.expand_path('../../libs/evt/event_listener', __FILE__)

class WebSocketServer
  include EventListener

  def start(ip, port)
    @sockets = []
    @server = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0)
    @server.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, [1].pack('i'))
    addr = Socket.sockaddr_in(port, ip);
    @server.bind(addr)
    @server.listen(10)
    #@tcp_server = TCPServer.open(port)
    @connections = {}
    server_ip = Socket.ip_address_list.detect { |intf| intf.ipv4_private? }.ip_address

    sp 'Server started at '+server_ip.to_s+':'+port.to_s

    trigger (Event.new('server_started',
                       {
                           started_at: Time.new.localtime,
                           server: {
                               ip: server_ip,
                               port: port
                           }
                       }))
    @sockets << @server
    run
  end

  def run
    while true
      changed = IO.select(@sockets)
      changed.each do |s, s_addr|
        next if s.nil?
        if (s==@server)
          socket, client_addr = s.accept
          next if !socket
          begin
            @sockets << socket
            sp 'New client connected ' + socket.to_s
            ws = WebSocket.new(self, socket)
            @connections[socket.to_s] = ws
            trigger(Event.new('connect', {server: self, web_socket: ws}))
          rescue Exception => e
            sp 'Some error occured'
            sp $!
            sp e.backtrace
          ensure
            #ws.close
          end
        else
          unless @connections[s.to_s].nil?
            begin
              p s.to_s
              message = @connections[s.to_s].receive
              trigger(Event.new('receive', {server: self, web_socket: @connections[s.to_s], message: message})) unless message.nil?
            rescue Exception => e
              sp 'Some error occurred'
              sp $!
              sp e.backtrace
            ensure
            end
          end
        end
      end
    end
  end

  private
end