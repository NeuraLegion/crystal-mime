require "./spec_helper"

describe MIME do
  # [RFT1341](https://datatracker.ietf.org/doc/html/rfc1341#page-75)
  it "Ensure test mail is RFC 1341 compliant" do
    # Ensure CRLF's are present in test:
    f = {{ read_file("#{__DIR__}/test-mime1.email") }}
    crlf = f.gsub(/\r\n/, "\n").gsub(/\n/, "\r\n")
    f.should eq(crlf)
  end

  # From [Email for Users & Programmers](https://rand-mh.sourceforge.io/book/overall/mulmes.html)
  it "Parses test1 email" do
    # Ensure CRLF's are present in test:
    f = {{ read_file("#{__DIR__}/test-mime1.email") }}
    crlf = f.gsub(/\r\n/, "\n").gsub(/\n/, "\r\n")

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

  describe "Parses base64-encoded emails" do
    it "with a single body" do
      f = {{ read_file("#{__DIR__}/test-mime3.email") }}
      email = MIME.mail_object_from_raw(f)

      expected_body = <<-PLAIN
      Hello, Anna.
      A new vacation is available at the office. Please let me know if you're interested.
      Sincerely, Jonh.
      PLAIN

      email.body_text.should eq expected_body
    end

    it "with multipart" do
      f = {{ read_file("#{__DIR__}/test-mime4.email") }}
      email = MIME.mail_object_from_raw(f)

      expected_text_body = <<-PLAIN
      Hello, Anna.
      A new vacation is available at the office. Please let me know if you're interested.
      Sincerely, Jonh.
      PLAIN

      expected_html_body = <<-PLAIN
      <h1>Hello, Anna.</h1>
      <p>A new vacation is available at the office. Please let me know if you're interested.</p>
      <hr>
      <p>Sincerely, Jonh.</p>
      PLAIN

      email.body_text.should eq expected_text_body
      email.body_html.should eq expected_html_body
    end
  end

  describe "Parses email with multipart inside multipart" do
    it "with multipart alternative inside mixed" do
      f = {{ read_file("#{__DIR__}/test-mime-with-mixed-multipart.eml") }}
      email = MIME.mail_object_from_raw(f)
      expected_html_body = <<-PLAIN
      <p>We see you&rsquo;re trying to create (or update) your XXX account. Use the following security code to verify your info. This code will only be valid for 20 minutes.</p>
      <p>Your one-time security code: <span style="text-decoration: underline;"><strong>456748</strong></span></p>
      <p><b>DO NOT SHARE.</b> Only enter it online.  Our reps will never ask for it.</p>
      <p>If you didn&rsquo;t make this request, contact us immediately at 111-111-1113.</p>
      <p>XXX</p>
      PLAIN
      expected_html_body = expected_html_body.gsub(/\r\n/, "\n").gsub(/\n/, "\r\n")
      email.body_html.should eq expected_html_body

      expected_text_body = <<-PLAIN
      We see you are trying to create (or update) your XXX account. Use the following security code to verify your info. This code will only be valid for 20 minutes.
      Your one-time security code: 456748
      DO NOT SHARE. Only enter it online.  Our reps will never ask for it.
      If you didn&rsquo;t make this request, contact us immediately at 111-111-1113.
      XXX
      PLAIN
      expected_text_body = expected_text_body.gsub(/\r\n/, "\n").gsub(/\n/, "\r\n")
      email.body_text.should eq expected_text_body
    end
  end
end
