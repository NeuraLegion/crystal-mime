require "mime/multipart"
require "time"

# TODO: Write documentation for `Crystal::MIME`
module MIME
  VERSION = "0.1.5"

  struct Email
    property from
    property to
    property subject
    property datetime
    def initialize(@from : String, @to : String, @subject : String, @datetime : Time)
    end
  end

  def self.pack_h_star(str_array)
    String.build do |io|
      str_array.each do |number|
        if number.to_i(16) > 256
          puts("** Ignoring **")
          puts("Num: #{number}")
          puts("Num.to_i: #{number.to_i(16)}")
          puts("Num.to_i.chr: #{number.to_i(16).chr}")
        else
          io.write_byte number.to_i(16).to_u8
        end
      end
    end
  end

  def self.unescape(string)
    str=string.tr("+", " ").gsub(/((?:%[0-9a-fA-F]{2})+)/) do |m|
      # [m.delete("%")].pack("H*")
      # puts(m.split("%").compact)
      pack_h_star(m.split("%", remove_empty: true))
    end # .force_encoding(encoding)
    # str.valid_encoding? ? str : str.force_encoding(string.encoding)
  end

  # Mail looks like:
  # Content-Type=multipart%2Fmixed%3B+boundary%3D%22------------020601070403020003080006%22&Date=Fri%2...
  def self.parse_raw(escaped_mime_data)
    unescaped_mime_data = HTML.unescape(escaped_mime_data)
    # puts unescaped_mime_data.split("\n").first.split("&").first
    data    = Hash(String, String).new
    unescaped_mime_data.split("&").each do |p|
      k,v = p.split("=")
      data[k] = unescape(v)
    end

    content_type = data["Content-Type"]?
    if content_type
      boundary  = "#{MIME::Multipart.parse_boundary(content_type)}"

      # Manual parse:
      parts = Array(String).new
      buf   = Array(String).new
      data["body-mime"].split("\n") do |line|
        if(line == "--#{boundary}")
          parts << buf.join("\n")
          buf = Array(String).new
        elsif(line == "--#{boundary}--") # Terminal boundary
          parts << buf.join("\n") unless buf.empty?
          buf = Array(String).new # But really should be done
        else
          buf << line
        end
      end
      non_mime = parts.shift # https://en.wikipedia.org/wiki/MIME#Multipart_messages
      return { headers: data, non_mime: non_mime, mime: parts }
    else
      return { headers: data }
    end
  end

  def self.mail_object_from_raw(raw_mime_data)
    parsed = parse_raw(raw_mime_data)
    Email.new(from:     parsed[:headers]["From"],
              to:       parsed[:headers]["To"]? || parsed[:headers]["recipient"],
              subject:  parsed[:headers]["Subject"]? || "",    
              datetime: Time::Format::RFC_2822.parse(parsed[:headers]["Date"]))
  end

end
