require "benchmark"
require "benchmark-memory"
require "builder"
require "active_support/core_ext/hash/conversions"
require "rabl"
require "nokogiri"
# require "libxml"
require "ox"

class BaseModel
  def initialize(attrs = {})
    attrs.each { |k, v| self.send("#{k}=", v) }
  end
end

class UserModel < BaseModel
  attr_accessor :name, :age, :email
end

class CommentModel < BaseModel
  attr_accessor :user, :message, :created_at, :attachment
end

class PostModel < BaseModel
  attr_accessor :content, :author, :comments, :created_at, :published
end

def create_post(size = 1_000, comments = 10, attachment_size = 0)
  PostModel.new(
    content: "-" * size,
    author: UserModel.new(name: "First Last", age: rand(100), email: "user@email.com"),
    created_at: Time.now,
    published: true,
    comments: comments.times.map do
      CommentModel.new(
        user: UserModel.new(name: "First Last", age: rand(100), email: "user@email.com"),
        message: "-" * 400,
        created_at: Time.now,
        attachment: "-" * attachment_size,
      )
    end,
  )
end

post1 = create_post(1_000, 10, 0)
post2 = create_post(1_000_000, 200, 1_000)
# post3 = create_post(5_000_000, 2_000, 5_000)
post3 = create_post(5, 2, 5)

# uses Builder
# https://github.com/rails/rails/blob/5-2-stable/activesupport/lib/active_support/core_ext/hash/conversions.rb#L75-L92
# def render_toxml(post)
#   {
#     "content" => post.content,
#     "created_at" => post.created_at,
#     "published" => post.published,

#     "author" => {
#       "name" => post.author.name,
#       "age" => post.author.age,
#       "email" => post.author.email,
#     },

#     "comments" => post.comments.map do |comment|
#       {
#         "created_at" => comment.created_at,
#         "message" => comment.message,
#         "user" => {
#           "name" => comment.user.name,
#           "age" => comment.user.age,
#           "email" => comment.user.email,
#         },
#         "attachment" => comment.attachment,
#       }
#     end,
#   }.to_xml(root: "post")
# end

# def render_stringc(post) # more concatenation
#   xml = '<?xml version="1.0" encoding="UTF-8"?>'
#   xml << "<post>"
#   xml << "  <content>#{post.content.encode(xml: :text)}</content>"
#   xml << "  <created-at type=\"dateTime\">#{post.created_at.iso8601}</created-at>"
#   xml << "  <published type=\"boolean\">#{post.published}</published>"
#   xml << "  <author>"
#   xml << "    <name>#{post.author.name.encode(xml: :text)}</name>"
#   xml << "    <age type=\"integer\">#{post.author.age}</age>"
#   xml << "    <email>#{post.author.email.encode(xml: :text)}</email>"
#   xml << "  </author>"
#   xml << '  <comments type="array">'
#   post.comments.each do |comment|
#     xml << "  <comment>"
#     xml << "    <created-at type=\"dateTime\">#{comment.created_at.iso8601}</created-at>"
#     xml << "    <message>#{comment.message.encode(xml: :text)}</message>"
#     xml << "    <user>"
#     xml << "      <name>#{comment.user.name.encode(xml: :text)}</name>"
#     xml << "      <age type=\"integer\">#{comment.user.age}</age>"
#     xml << "      <email>#{comment.user.email.encode(xml: :text)}</email>"
#     xml << "    </user>"
#     xml << "    <attachment>#{comment.attachment.encode(xml: :text)}</attachment>"
#     xml << "  </comment>"
#   end
#   xml << "  </comments>"
#   xml << "</post>"
#   xml
# end

# def render_stringi(post) # only interpolation
#   %(<?xml version="1.0" encoding="UTF-8"?>
# <post>
#   <content>#{post.content.encode(xml: :text)}</content>
#   <created-at type="dateTime">#{post.created_at.iso8601}</created-at>
#   <published type="boolean">#{post.published}</published>
#   <author>
#     <name>#{post.author.name.encode(xml: :text)}</name>
#     <age type="integer">#{post.author.age}</age>
#     <email>#{post.author.email.encode(xml: :text)}</email>
#   </author>
#   <comments type="array">
#   #{post.comments.map do |comment|
#     %(
#       <comment>
#         <created-at type="dateTime">#{comment.created_at.iso8601}</created-at>
#         <message>#{comment.message.encode(xml: :text)}</message>
#         <user>
#           <name>#{comment.user.name.encode(xml: :text)}</name>
#           <age type="integer">#{comment.user.age}</age>
#           <email>#{comment.user.email.encode(xml: :text)}</email>
#         </user>
#         <attachment>#{comment.attachment.encode(xml: :text)}</attachment>
#       </comment>
# )
#   end.join("")}
#   </comments>
# </post>)
# end

# def render_rabl(post)
#   # # Create a post.rabl file with the following content
#   attribute :content
#   attribute :created_at
#   attribute :published

#   child(:author) do
#     attribute :name
#     attribute :age
#     attribute :email
#   end

#   child(:comments) do
#     attribute :created_at
#     attribute :message
#     child(:user) do
#       attribute :name
#       attribute :age
#       attribute :email
#     end
#     attribute :attachment
#   end
#   Rabl.render(post, "post", view_path: ".", format: :xml, root: "post")
# end

def render_builder(post)
  xml = Builder::XmlMarkup.new
  xml.instruct! :xml, version: "1.0", encoding: "UTF-8"
  xml.post do |builder|
    builder.content post.content
    builder.created_at post.created_at, type: "dateTime"
    builder.published post.published, type: "boolean"
    builder.author do |builder|
      builder.name post.author.name
      builder.age post.author.age, type: "integer"
      builder.email post.author.email
    end
    post.comments.each do |comment|
      builder.comments do |builder|
        builder.created_at comment.created_at, type: "dateTime"
        builder.message comment.message
        builder.user do |builder|
          builder.name comment.user.name
          builder.age comment.user.age, type: "integer"
          builder.email comment.user.email
        end
        builder.attachment comment.attachment
      end
    end
  end
end

def render_nokogiri(post)
  Nokogiri::XML::Builder.new do |xml|
    xml.post do
      xml.content post.content
      xml.created_at post.created_at, type: "dateTime"
      xml.published post.published, type: "boolean"
      xml.author do
        xml.name post.author.name
        xml.age post.author.age, type: "integer"
        xml.email post.author.email
      end
      post.comments.each do |comment|
        xml.comments do
          xml.created_at comment.created_at, type: "dateTime"
          xml.message comment.message
          xml.user do
            xml.name comment.user.name
            xml.age comment.user.age, type: "integer"
            xml.email comment.user.email
          end
          xml.attachment comment.attachment
        end
      end
    end
  end.to_xml
end

# def render_libxml(post)
#   doc = LibXML::XML::Document.new
#   doc.encoding = LibXML::XML::Encoding::UTF_8
#   doc.root = root = LibXML::XML::Node.new("post")

#   node = LibXML::XML::Node.new("content")
#   node.content = post.content
#   root << node

#   node = LibXML::XML::Node.new("created-at")
#   node.content = post.created_at.iso8601
#   LibXML::XML::Attr.new(node, "type", "dateTime")
#   root << node

#   node = LibXML::XML::Node.new("published")
#   node.content = post.published.to_s
#   LibXML::XML::Attr.new(node, "type", "boolean")
#   root << node

#   author = LibXML::XML::Node.new("author")

#   node = LibXML::XML::Node.new("name")
#   node.content = post.author.name
#   author << node

#   node = LibXML::XML::Node.new("age")
#   node.content = post.author.age.to_s
#   LibXML::XML::Attr.new(node, "type", "integer")
#   author << node

#   node = LibXML::XML::Node.new("email")
#   node.content = post.author.email
#   author << node

#   root << author

#   comments = LibXML::XML::Node.new("comments")
#   LibXML::XML::Attr.new(comments, "type", "array")
#   post.comments.each do |comment|
#     node_comment = LibXML::XML::Node.new("comment")

#     node = LibXML::XML::Node.new("created-at")
#     node.content = comment.created_at.iso8601
#     LibXML::XML::Attr.new(node, "type", "dateTime")
#     node_comment << node

#     node = LibXML::XML::Node.new("message")
#     node.content = comment.message
#     node_comment << node

#     user = LibXML::XML::Node.new("user")

#     node = LibXML::XML::Node.new("name")
#     node.content = comment.user.name
#     user << node

#     node = LibXML::XML::Node.new("age")
#     node.content = comment.user.age.to_s
#     LibXML::XML::Attr.new(node, "type", "integer")
#     user << node

#     node = LibXML::XML::Node.new("email")
#     node.content = comment.user.email
#     user << node

#     node_comment << user

#     node = LibXML::XML::Node.new("attachment")
#     node.content = comment.attachment
#     node_comment << node

#     comments << node_comment
#   end

#   root << comments

#   doc.to_s
# end

def render_ox(post)
  doc = Ox::Document.new(:version => "1.0")

  instruct = Ox::Instruct.new(:xml)
  instruct[:version] = "1.0"
  instruct[:encoding] = "UTF-8"
  doc << instruct

  root = Ox::Element.new("post")
  doc << root

  node = Ox::Element.new("content")
  node << post.content
  root << node

  node = Ox::Element.new("created-at")
  node[:type] = "dateTime"
  node << post.created_at.iso8601
  root << node

  node = Ox::Element.new("published")
  node[:type] = "boolean"
  node << post.published.to_s
  root << node

  author = Ox::Element.new("author")

  node = Ox::Element.new("name")
  node << post.author.name
  author << node

  node = Ox::Element.new("age")
  node[:type] = "integer"
  node << post.author.age.to_s
  author << node

  node = Ox::Element.new("email")
  node << post.author.email
  author << node

  root << author

  comments = Ox::Element.new("comments")
  comments[:type] = "array"
  post.comments.each do |comment|
    node_comment = Ox::Element.new("comment")

    node = Ox::Element.new("created-at")
    node[:type] = "dateTime"
    node << comment.created_at.iso8601
    node_comment << node

    node = Ox::Element.new("message")
    node << comment.message
    node_comment << node

    user = Ox::Element.new("user")

    node = Ox::Element.new("name")
    node << comment.user.name
    user << node

    node = Ox::Element.new("age")
    node[:type] = "integer"
    node << comment.user.age.to_s
    user << node

    node = Ox::Element.new("email")
    node << comment.user.email
    user << node

    node_comment << user

    node = Ox::Element.new("attachment")
    node << comment.attachment
    node_comment << node

    comments << node_comment
  end

  root << comments

  Ox.dump(doc)
end

# Confirm rendering is working fine
puts "Are the renderers consistent?"
# puts ([render_stringc(post1), render_stringi(post1), render_toxml(post1),
#        render_builder(post1), render_rabl(post1), render_nokogiri(post1),
#        render_libxml(post1), render_ox(post1)].map { |xml| Hash.from_xml(xml) }.uniq.size == 1)

puts ([render_builder(post1), render_nokogiri(post1),
       render_ox(post1)].map { |xml| Hash.from_xml(xml) }.uniq.size == 1)

[post1, post2, post3].each_with_index do |post_i, i|
  puts
  puts "------------------"
  puts "Benchmark of post#{i + 1}"
  puts "------------------"

  nrep = 1000
  bench = Benchmark.bm(10) do |x|
    # x.report("toxml:") { nrep.times { render_toxml(post_i) } }
    # x.report("stringc:") { nrep.times { render_stringc(post_i) } }
    # x.report("stringi:") { nrep.times { render_stringi(post_i) } }
    # x.report("rabl:") { nrep.times { render_rabl(post_i) } }
    x.report("builder:") { nrep.times { render_builder(post_i) } }
    x.report("nokogiri:") { nrep.times { render_nokogiri(post_i) } }
    # x.report("libxml:") { nrep.times { render_libxml(post_i) } }
    x.report("ox:") { nrep.times { render_ox(post_i) } }
  end

  puts
  puts "Results in ms per execution:"
  bench.each do |bm|
    puts ">>>>> #{bm.label} - %.3f ms" % (bm.real * 1000.0 / nrep)
  end
  puts

  Benchmark.memory do |x|
    # x.report("toxml:") { render_toxml(post_i) }
    # x.report("stringc:") { render_stringc(post_i) }
    # x.report("stringi:") { render_stringi(post_i) }
    # x.report("rabl:") { render_rabl(post_i) }
    x.report("builder:") { render_builder(post_i) }
    x.report("nokogiri:") { render_nokogiri(post_i) }
    # x.report("libxml:") { render_libxml(post_i) }
    x.report("ox:") { render_ox(post_i) }
    x.compare!
  end
end

p "Done!"
