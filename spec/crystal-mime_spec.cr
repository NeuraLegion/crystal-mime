require "./spec_helper"

describe MIME do
  # [RFT1341](https://datatracker.ietf.org/doc/html/rfc1341#page-75)
  it "Ensure test mail is RFC 1341 compliant" do
    # Ensure CRLF's are present in test:
    f = {{ read_file("#{__DIR__}/test-mime1.email") }}
    crlf = f.gsub(/\r\n/,"\n").gsub(/\n/,"\r\n")
    f.should eq(crlf)
  end

  # From [Email for Users & Programmers](https://rand-mh.sourceforge.io/book/overall/mulmes.html)
  it "Parses test1 email" do
    # Ensure CRLF's are present in test:
    f = {{ read_file("#{__DIR__}/test-mime1.email") }}
    crlf = f.gsub(/\r\n/,"\n").gsub(/\n/,"\r\n")

    email = MIME.mail_object_from_raw(crlf)
    email.from.should eq("Jerry Peek <jerry@ora.com>")

    # puts email.inspect
    # puts "body: #{email.body_text}"
    body_text = email.body_text
    body_text.should be_a(String)
    body_text && body_text.should start_with("We've just released")
    
    true.should eq(true)
  end

  it "Follows RFC 2047" do
    str = RFC2047.decode("=?UTF-8?q?Yo_=F0=9F=90=95?=")
    str.should eq("Yo 🐕")
  end
  
  it "Parses multi-line RFC2047-encoded headers" do
    f = {{ read_file("#{__DIR__}/test-mime2.email") }}
    email = MIME.mail_object_from_raw(f)
    email.from.should eq("Случайный Пользователь <random-user@example.com>")
  end
end
