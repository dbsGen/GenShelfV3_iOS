require 'object'
require 'models'
require 'http_client'
require 'callback'
require 'data'
require 'xml'
require 'duktape'
require 'encoder'


# 主页解析文件
# 必须重载 :load :search 和 :loadBook 三个方法
class Library < HiEngine::Object

  HOST_URL = 'http://comic.kukudm.com'
  
  @areas = nil
  @types = nil

  # 加载主页接口。
  # @method load
  # @param page 分页，从0开始
  # @param on_complete 结束回调
  # => 成功: on_complete.inv true, books([Book...]), no_more(bool)
  # => 失败: on_complete.inv false
  # @return client 把请求反回，让主程序页面退出的时候有能力结束请求。
  #   不过这个client并不是关键要素，所以有一串请求时也不必担心，返回最开始的一个就行。
  def load page, on_complete
    if !@duktape
    	@duktape = DuktapeEngine.new
    end
    type = settings.find '类型'
    t = case type
    when 0
      3
    when 1
      5
    when 2
      30
    when 3
      31
    else
      3
    end
    url = HOST_URL + "/comictype/#{t}_#{page+1}.htm"
    client = HTTPClient.new url
    client.on_complete = Callback.new do |c|
      if c.getError.length == 0
        doc = XMLDocument.new FileData.new(c.path), 1
        nodes = doc.xpath "//dl[@id='comicmain']/dd"
        books = []
        nodes.each do |node|
        	book = Book.new
        	links = node.xpath 'a'
        	book.url = HOST_URL + links[0].attr('href')
            book.thumb = @duktape.eval "encodeURI(\"#{links[0].getChild(0).attr('src')}\")"
            book.name = links[1].getContent
        	book.subtitle = node.getContent.gsub(book.name, '').strip
        	books << book
        end
        no_more = true
        links = doc.xpath("//dl[@id='comicmain']/following-sibling::table//a")
        links.each do |link|
        	if link.getContent.strip == '下一页'
        		no_more = false
        		break
        	end
        end
        p "no more #{no_more}"
        on_complete.inv true, books, no_more
      else
        on_complete.inv false
      end
    end
    client.start
    client
  end

  # 读去书本详细信息的接口。
  # @method loadBook
  # @param book Book对象
  # @param page 分页，从0开始
  # @param on_complete 结束回调
  # => 成功: on_complete.inv true, new_book(Book), chapters([Chapter...]), no_more(bool)
  # => 失败: on_complete.inv false
  # @return client 把请求反回，让主程序页面退出的时候有能力结束请求。
  def loadBook book, page, on_complete
    client = HTTPClient.new book.url
    client.on_complete = Callback.new do |c|
      if c.getError.length == 0
        doc = XMLDocument.new FileData.new(c.path), 1
        chapters = []
        nodes = doc.xpath "//dl[@id='comiclistn']/dd"
        nodes.reverse_each do |node|
        	as = node.getChildren
        	if as.size > 0
              	chapter = Chapter.new
        		o = as[0]
        		chapter.url = HOST_URL + o.attr('href')
        		ns = o.getContent.split(' ')
        		chapter.name = ns.last
              	chapters << chapter
        	end
        end
        nb = Book.new
        nb.url = book.url
        nb.name = book.name
        nb.thumb = book.thumb
        nb.subtitle = book.subtitle
        nb.des = doc.xpath("//div[@id='ComicInfo']").first.getContent
        on_complete.inv true, nb, chapters, false
      else
        on_complete.inv false
      end
    end
    client.start
    client
  end


  # @description 搜索接口
  # @param key 搜索关键字
  # @param page 分页，从0开始
  # @param on_complete 结束回调
  # => 成功: on_complete.inv true, books([Book...]), no_more(bool)
  # => 失败: on_complete.inv false
  # @return client 把请求反回，让主程序页面退出的时候有能力结束请求。
  def search key, page, on_complete
    url = "http://so.kukudm.com/search.asp?kw=#{Encoder::urlEncodeWithEncoding key, "gbk"}&page=#{page+1}"
    client = HTTPClient.new url
    client.on_complete = Callback.new do |c|
      if c.getError.length == 0
        doc = XMLDocument.new FileData.new(c.path), 1
        nodes = doc.xpath "//dl[@id='comicmain']/dd"
        books = []
        nodes.each do |node|
        	book = Book.new
        	links = node.xpath 'a'
        	book.url = links[0].attr('href')
            book.thumb = @duktape.eval "encodeURI(\"#{links[0].getChild(0).attr('src')}\")"
            book.name = links[1].getContent
        	book.subtitle = node.getContent.gsub(book.name, '').strip
        	books << book
        end
        no_more = true
        links = doc.xpath("//table[@width='100%']/following-sibling::div/a")
        links.each do |link|
        	if link.getContent.strip == '下一页'
        		no_more = false
        		break
        	end
        end
        on_complete.inv true, books, no_more
      else
        on_complete.inv false
      end
    end
    client.start
    client
  end

end
