require 'base64'
require 'digest/sha1'
require File.expand_path('../web_socket_frame', __FILE__)
class WebSocket

  def initialize(server, socket)
    @server = server
    @socket = socket
    @handshaked = false
    handshake
  end

  def send(message)
    sp message
    @socket.write(WebSocketFrame.new(WebSocketFrame::Text, message)) if @handshaked
  end

  def receive
    firstByte = @socket.read(1)
    unless firstByte.nil?
      dataType = firstByte.unpack('B*')[0]
      secondByte = @socket.read(1)
      masked = secondByte.unpack('B*')[0][0] == '1'
      len = secondByte.unpack('C*')[0].ord & 127
      case len
        when 126
          data_len = @socket.read(2).unpack('B*')[0].to_i(2)
        when 127
          data_len = @socket.read(8).unpack('B*')[0].to_i(2)
        else
          data_len = len
      end
      mask = @socket.read(4).unpack('C*')
      data = @socket.read(data_len).unpack('C*')
      if masked
        message = []
        data.each_with_index { |b, i| message << (b ^ mask[i%4]) }
        message = message.pack('C*')
      else
        message = data
      end
      message
    else
      #@socket.close
    end
  end

  def handshake
    header = parse_header
    unless header['Sec-WebSocket-Key'].nil?
      response = [
          'HTTP/1.1 101 Switching Protocols',
          'Upgrade: websocket',
          'Connection: Upgrade',
          'Sec-WebSocket-Accept: ' + generate_sec_key(header['Sec-WebSocket-Key'])
      ].join("\r\n")+"\r\n\r\n"
      sp response
      @socket.write(response)
      @handshaked = true
    end
  end

  def close
    @socket.close
  end

  private
  def parse_header
    header = {}
    while line = @socket.gets
      line.chomp!
      break if line.empty?
      cp line
      line =~ /\A(\S+): (.*)\z/n
      header[$1] = $2 unless $1.nil?
    end
    header
  end

  def generate_sec_key(key)
    magic = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
    Base64.encode64(Digest::SHA1.digest(key + magic)).gsub!(/\n/, '')
  end
end