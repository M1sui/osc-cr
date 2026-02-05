Version = 1.63

require "socket"

class OSC
  def initialize(host : String, send_port : Int32, recv_port : Int32)
    @send_socket = UDPSocket.new
    @send_address = Socket::IPAddress.new(host, send_port)

    @recv_socket = UDPSocket.new
    @recv_socket.reuse_address = true
    @recv_socket.bind("0.0.0.0", recv_port)

    @hnd = Hash(String, Proc(OSCEvent, Nil)).new
    @hnd0 = nil.as(Proc(OSCEvent, Nil)?)
  end

  class OSCData
    getter path
    getter type
    getter val

    def initialize(@path : String, @type : String, @val : Bool | Int32 | Float32 | String | Nil)
    end

    def to_s(io : IO)
      @val.to_s(io)
    end
  end

  class OSCEvent
    getter path
    getter data
    getter datas

    def initialize(@path : String, @data : OSCData, @datas : Array(OSCData))
    end
  end

  def message(*, path : String, &blk : OSCEvent -> Nil)
    @hnd[path] = blk
  end

  def message(&blk : OSCEvent -> Nil)
    @hnd0 = blk
  end

  def run
    puts "OSC Version #{Version}"
    spawn { rcvlp }
  end

  def sendb(path : String, val : Bool)
    pkt = Bytes.new(0)
    pkt += pstr(path)
    pkt += pstr(val ? ",T" : ",F")
    @send_socket.send(pkt, @send_address)
  end

  def sendi(path : String, val : Int32)
    pkt = Bytes.new(0)
    pkt += pstr(path)
    pkt += pstr(",i")
    pkt += i32(val)
    @send_socket.send(pkt, @send_address)
  end

  def sendf(path : String, val : Float32)
    pkt = Bytes.new(0)
    pkt += pstr(path)
    pkt += pstr(",f")
    pkt += f32(val)
    @send_socket.send(pkt, @send_address)
  end

  def rcvlp
    buf = Bytes.new(4096)
    while true
      len, _adr = @recv_socket.receive(buf)
      ev = parseev(buf[0, len])
      if ev
        h = @hnd[ev.path]?
        if h
          h.call(ev)
        elsif (h0 = @hnd0)
          h0.call(ev)
        end
      end
    end
  end

  private def parseev(msg : Bytes)
    idx = 0
    path, idx = rstr(msg, idx)

    tag, idx = rstr(msg, idx)
    return nil unless tag.starts_with?(",")

    dats = Array(OSCData).new
    i = 1
    while i < tag.size
      t = tag.byte_at(i)
      if t == 'i'.ord
        v, idx = ri32(msg, idx)
        dats << OSCData.new(path, "int", v)
      elsif t == 'f'.ord
        v, idx = rf32(msg, idx)
        dats << OSCData.new(path, "float", v)
      elsif t == 's'.ord
        v, idx = rstr(msg, idx)
        dats << OSCData.new(path, "string", v)
      elsif t == 'T'.ord
        dats << OSCData.new(path, "bool", true)
      elsif t == 'F'.ord
        dats << OSCData.new(path, "bool", false)
      else
        dats << OSCData.new(path, "?", nil)
      end
      i += 1
    end

    dat = dats[0]? || OSCData.new(path, "none", nil)
    OSCEvent.new(path, dat, dats)
  rescue
    nil
  end

  private def pstr(str : String)
    buf = str.to_slice
    len = buf.size + 1
    pad = (4 - (len % 4)) % 4
    out = Bytes.new(len + pad, 0_u8)
    out[0, buf.size].copy_from(buf)
    out
  end

  private def i32(v : Int32)
    out = Bytes.new(4)
    out[0] = ((v >> 24) & 0xFF).to_u8
    out[1] = ((v >> 16) & 0xFF).to_u8
    out[2] = ((v >>  8) & 0xFF).to_u8
    out[3] = ( v        & 0xFF).to_u8
    out
  end

  private def f32(v : Float32)
    u = v.unsafe_as(UInt32)
    out = Bytes.new(4)
    out[0] = ((u >> 24) & 0xFF).to_u8
    out[1] = ((u >> 16) & 0xFF).to_u8
    out[2] = ((u >>  8) & 0xFF).to_u8
    out[3] = ( u        & 0xFF).to_u8
    out
  end

  private def rstr(msg : Bytes, idx : Int32)
    j = idx
    while j < msg.size && msg[j] != 0_u8
      j += 1
    end
    str = String.new(msg[idx, j - idx])
    j += 1
    pad = (4 - (j % 4)) % 4
    j += pad
    {str, j}
  end

  private def ri32(msg : Bytes, idx : Int32)
    b0 = msg[idx].to_i32
    b1 = msg[idx + 1].to_i32
    b2 = msg[idx + 2].to_i32
    b3 = msg[idx + 3].to_i32
    v  = (b0 << 24) | (b1 << 16) | (b2 << 8) | b3
    {v, idx + 4}
  end

  private def rf32(msg : Bytes, idx : Int32)
    b0 = msg[idx].to_u32
    b1 = msg[idx + 1].to_u32
    b2 = msg[idx + 2].to_u32
    b3 = msg[idx + 3].to_u32
    u  = (b0 << 24) | (b1 << 16) | (b2 << 8) | b3
    {u.unsafe_as(Float32), idx + 4}
  end
end
