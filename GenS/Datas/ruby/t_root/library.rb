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

  HOST_URL = 'http://manhua.dmzj.com'

  @areas = nil
  @types = nil

  def process_book doc, &block
    nodes = doc.xpath "//div[@class='cartoon_online_border']"
    if nodes.size == 0
      nodes = doc.xpath "//ul[contains(@class, 'list_con_li')]//a"
      nodes.each do |node|
        block.call node, false
      end
    else
      nodes.reverse_each do |node|
        block.call node, true
      end
      nodes = doc.xpath "//div[@class='cartoon_online_border_other']"
      nodes.each do |node|
        block.call node, true
      end
    end
  end

  def main_url page
    status = 0
    v = settings.find '状态'
    case v
    when 1
      status = 2309
    when 2
      status = 2310
    else
    end
    rg = 0
    v = settings.find '分类'
    case v
    when 1
      rg = 3262
    when 2
      rg = 3263
    when 3
      rg = 3264
    end
    zone = 0
    v = settings.find '地域'
    case v
    when 1
      zone = 2304
    when 2
      zone = 2305
    when 3
      zone = 2306
    when 4
      zone = 2307
    when 5
      zone = 2308
    when 6
      zone = 8435
    end
    type = 0
    v = settings.find '题材'
    unless @datas
      @datas = JSON.parse(file('subject.json').text)
    end
    if v != nil
      type = @datas.values[v]
    end
    order = 't'
    v = settings.find '排序'
    if v == 1
      order = 'h'
    end
    "http://s.acg.dmzj.com/mh/index.php?c=category&m=doSearch&status=#{status}&reader_group=#{rg}&zone=#{zone}&initial=all&type=#{type}&_order=#{order}&p=#{page+1}&callback=search.renderResult"
  end

  # 加载主页接口。
  # @method load
  # @param page 分页，从0开始
  # @param on_complete 结束回调
  # => 成功: on_complete.inv true, books([Book...]), no_more(bool)
  # => 失败: on_complete.inv false
  # @return client 把请求反回，让主程序页面退出的时候有能力结束请求。
  #   不过这个client并不是关键要素，所以有一串请求时也不必担心，返回最开始的一个就行。
  def load page, on_complete

    url = main_url page
    p url
    client = HTTPClient.new url
    client.on_complete = Callback.new do |c|
      if c.getError.length == 0
        if @javascript == nil
          @javascript = DuktapeEngine.new
          @javascript.eval file('pre.js').text
        end
        str = FileData.new(c.path).text
        ret = @javascript.eval(str)
        datas = JSON.parse ret
        books = []
        datas['result'].each do |book_node|
          book = Book.new
          book.name = book_node['name']
          cover = book_node['comic_cover']
          unless cover[/^https?:/]
            cover = 'http:' + cover
          end
          book.thumb = cover
          book.thumb_headers = {Referer: HOST_URL}
          u = book_node['comic_url']
          book.url = if u[/^https?:\/\//] then u else HOST_URL + u end
          book.subtitle = book_node['author']
          books << book
        end

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
        process_book doc do |node, is_doc|
          if is_doc
            b_nodes = node.xpath "ul//a"
            b_nodes.reverse_each do |node|
              chapter = Chapter.new
              chapter.url = HOST_URL + node.attr('href')
              chapter.name = node.getContent.strip
              chapters << chapter
            end
          else
            chapter = Chapter.new
            chapter.url = node.attr('href')
            chapter.name = node.getContent.strip
            chapters << chapter
          end
        end
        nb = Book.new
        nb.url = book.url
        nb.name = book.name
        nb.thumb = book.thumb
        nb.subtitle = book.subtitle
        nb.des = doc.xpath("//meta[@name='description']").first.attr('content')
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
    url = "http://s.acg.dmzj.com/comicsum/search.php?s=#{HTTP::URL::encode key}"
    client = HTTPClient.new url
    client.on_complete = Callback.new do |c|
      if c.getError.length == 0
        str = FileData.new(c.path).text
        datas = JSON.parse str.gsub(/^var g_search_data \= /, '')
        books = []
        datas.each do |book_node|
          book = Book.new
          book.name = book_node['name']
          book.thumb = book_node['cover']
          unless book.thumb[/^https?:\/\//]
            book.thumb = 'https:' + book.thumb
          end
          book.thumb_headers = {"Referer" => HOST_URL}
          book.url = book_node['comic_url']
          unless book.url[/^https?:\/\//]
            book.url = 'https:' + book.url
          end
          book.subtitle = book_node['comic_author']
          books << book
        end
        on_complete.inv true, books, true
      else
        on_complete.inv false
      end
    end
    client.start
    client
  end

end
