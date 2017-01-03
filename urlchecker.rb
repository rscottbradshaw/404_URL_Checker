#!/usr/bin/ruby

require 'net/http'
require 'net/smtp'

urls_found =[]
urls_ignored = []

file = File.open("/Users/scottbradshaw/code/404_URL_Checker", "r")
file.each do |line|
  next if line.strip! == ""
  line.insert(0, "http://") unless(line.match(/^http\:\/\//) || line.match(/^#/))
  if line.match(/^#/)
    urls_ignored.push(line)
  else
    urls_found.push(line)
  end
end
file.close

puts "Total # of urls found is: #{urls_found.length}"

status_code_404 = []
result = []
invalid_urls = []

urls_found.each_with_index do |url, i|
	begin
		res = Net::HTTP.get_response(URI(url))
		if res.code == "404"
      status_code_404.push(res)
    end
		result.push("#{url} returns: #{res.code}, #{res.message}")
	rescue
		result.push("#{url} returns: Error occurred - please check your URL.")
		invalid_urls.push(url)
	end
	print "* "
end

puts "\nTotal # of 404's: #{status_code_404.length}"
puts "Total # of Ignored URLS: #{urls_ignored.length}"
puts "Total # of Invalid URLs: #{invalid_urls.length}"
puts
puts "Emailing Results..."

email_message = <<MESSAGE_END
From: Your Name <your@mail.address>
To: Destination Address <someone@example.com>
Subject: URL Results

  The results of all URLs requested are as follows:
    -- Total # of URLs in the text file: #{urls_found.length}
    -- Total # of 404 NOT FOUND URLs: #{status_code_404.length}
    -- Total # of Ignored URLs(URLs Commented Out): #{urls_ignored.length}
    -- Total # of Invalid URLs: #{invalid_urls.length} (see full list below)

  List of URLs Checked:
    -- #{result.join("\n    -- ")}

  List of Invalid URLs, PLEASE RECHECK:
    -- #{invalid_urls.join("\n    -- ")}
MESSAGE_END

smtp = Net::SMTP.new('your.smtp.server', 25)
smtp.enable_starttls
smtp.start('your.smtp.server', 'your@mail.address', 'Your Password', :login)
smtp.send_message email_message, 'your@mail.address', 'someone@example.com'
smtp.finish
puts "Email sent!"
