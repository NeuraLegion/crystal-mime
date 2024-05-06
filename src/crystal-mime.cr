require "mime/multipart"
require "time"
require "quoted_printable"
require "./rfc2047"

# `MIME` Provides raw email parsing capabilities
module MIME
  VERSION = "0.1.17"

  struct Email
    property from
    property to
    property subject
    property datetime
    property body_html
    property body_text
    property attachments
    property headers
    def initialize(@from : String, @to : String, @subject : String, @datetime : Time | Nil, 
        @body_html : String | Nil, @body_text : String | Nil, @attachments : Array(String), @headers : Hash(String, String))
    end
  end

  # Support easy access with String
  def self.parse_raw(mime_str : String)
    self.parse_raw(IO::Memory.new(mime_str))
  end

  # Support efficient access as IO Stream
  # Mail looks like:
  # Content-Type=multipart%2Fmixed%3B+boundary%3D%22------------020601070403020003080006%22&Date=Fri%2...
  def self.parse_raw(mime_io : IO, boundary : String | Nil = nil )
    # Read headers in KEY: VAL format. RFC end is \n\n
    headers = Hash(String, String).new
    last_key = "MISSING"
    mime_io.each_line do |line|
      if line.starts_with?(/[\t ]/)        # Can have leading spaces or tabs
        if(last_key=="MISSING")
          puts "Unlikely that this is intended. Seeing line without a key:\n#{line}"
        end
        headers[last_key] += " " + RFC2047.decode(line.lstrip()) # Append everything but the spaces
      elsif line.blank?
        break
      else
        k,v = line.split(": ", 2)
        last_key = k

        # Patch up subject (from =?UTF-8?q?Yo_=F0=9F=90=95?= => 🦂)
        headers[k]=RFC2047.decode(v)
      end
    end
    
    parts = Hash(String, String).new
    body  = nil
    content_type = headers["Content-Type"]?
    if (boundary = is_multipart(content_type))
      # Should not be necessary, except that MIME::Multipart::Parser is too strict requiring CRLF
      # https://github.com/crystal-lang/crystal/blob/master/src/mime/multipart/parser.cr
      mime = mime_io.gets_to_end.gsub(/\r\n/, "\n").gsub(/\n/, "\r\n")
      # puts "MIME: #{mime.inspect}"
      mime_io = IO::Memory.new(mime)

      parser = MIME::Multipart::Parser.new(mime_io, boundary)
      while parser.has_next?
        parser.next do |headers, io|
          content_type = headers["Content-Type"].split("; ", 2).first
          content_transfer_encoding = headers["Content-Transfer-Encoding"]?
          content = io.gets_to_end
          # TODO: Handle the decoding of other content-transfer-encodings now.
          case content_transfer_encoding
            when "quoted-printable"
              # RFC2045 Section 6.7 (Quoted Printable or quoted-printable).
              # See also: https://www.hjp.at/doc/rfc/rfc1521.html
              parts[content_type] = QuotedPrintable.decode_string(content)
            when "base64"
              parts[content_type] = Base64.decode_string(content)
            else
              parts[content_type] = content
          end
        end
      end
    else
      body = mime_io.gets_to_end
    end

    return { headers: headers, parts: parts, body: body }
  end

  def self.mail_object_from_raw(raw_mime_data)
    parsed = parse_raw(raw_mime_data)
    # return Email.new(from: "", to: "", subject: "", datetime: nil, body_html: "", body_text: "", attachments: [] of String)
    if parsed[:headers]["Date"]?
      datetime = Time::Format::RFC_2822.parse(parsed[:headers]["Date"])
    else
      datetime = nil
    end
    # puts parsed.inspect
    Email.new(from:     parsed[:headers]["From"],
              to:       parsed[:headers]["To"]? || parsed[:headers]["recipient"],
              subject:  parsed[:headers]["Subject"]? || "",    
              datetime: datetime,
              body_html: parsed[:parts]["text/html"]?,
              body_text: parsed[:parts]["text/plain"]?,
              attachments: [] of String,
              headers: parsed[:headers]
              )
  end

  def self.is_multipart(content_type : Nil)
    return nil
  end
  def self.is_multipart(content_type : String)
    if content_type =~ /^multipart/ 
        "#{MIME::Multipart.parse_boundary(content_type)}"
    else
      nil
    end
  end
end
