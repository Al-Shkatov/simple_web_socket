class WebSocketFrame

  Continue = 0b10000000
  Text = 0b10000001
  Binary = 0b10000010
  Close = 0b10001000
  Ping = 0b10001001
  Pong = 0b10001010

  NeedData = [Text, Binary]

  def initialize(type, data = nil)
    raise ArgumentError if data.nil? && NeedData.include?(type)
    bytes = [[type].pack('c')]
    len = data.length
    if (len<126)
      bytes << [len].pack('c')
    elsif len < 2**16
      bytes << 126.chr
      bytes << [data.bytesize].pack('n')
    else
      bytes << 127.chr
      bytes << [data.bytesize/(2**32), data.bytesize%(2**32)].pack('NN')
    end
    bytes << data.to_s
    bytes = bytes.join
    bytes
  end
end