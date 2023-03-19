require "builder"

s = [1, 20, "sdfds", "XCsfdfsdf", { :d => "ddd", :a => "ssssss", :c => "ccccccccc" }, "adas"]

s.each do |item|
  p item if item.is_a? Hash
end

builder = Builder::XmlMarkup.new(:indent => 2)
xml = ""
5.times do |i|
  builder.person { |b| b.name("Jim#{i}"); b.phone("555-1234-#{i}") }
end
xml << builder.target!

File.write("test.xml", xml, mode: "a")

File.open("test.xml", "a") do |f|
  f.puts xml
end
