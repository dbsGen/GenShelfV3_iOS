require 'object'
require 'models'
require 'http_client'
require 'callback'
require 'data'
require 'xml'
require 'duktape'

# 解析每个章节中的各个page
# 必须重载 :process :stop 和 :reloadPage 三个方法
# 
# @method loadedPage 当process中读取到一页数据时调用。
# @param index int 当前页数从0开始
# @param success bool 是否成功
# @param page Page 读取到的page数据用Page来传递
#
# @property on_page_count Callback 当process中读取到一共有多少页时调用。
# => 成功: on_page_count.inv true, total(int)
# => 失败: on_page_count.inv false
class Reader < HiEngine::Object
  HOST_URL = 'http://images.dmzj.com/'
  @stop = false
  @duktape = nil

  # 开始解析一个章节，读取其中所有的页
  # @param chapter Chapter 章节信息
  def process chapter
    url = chapter.url
    @stop = false
    p url

    @client = HTTPClient.new url
    @client.read_cache = true
    @client.on_complete = Callback.new do |c|
      @client = nil
      if c.getError.length == 0
      	if @duktape == nil
      	  @duktape = DuktapeEngine.new
      	  @duktape.eval file('read.js').text
      	end
      	doc = XMLDocument.new FileData.new(c.path), 1
      	@duktape.eval doc.xpath("//head/script[not(@src)]").first.getContent
      	arr_pages = @duktape.eval('getPages()')
      	idx = 0
      	arr_pages.each do |p|
          page = Page.new
          page.status = 1
          page.url = url
          page.picture = HOST_URL + p
          page.addHeader "Referer", page.url
          loadedPage idx, true, page
      	  idx = idx + 1
      	end
      	on_page_count.inv true, arr_pages.size
      else
      	on_page_count.inv false
      end
    end
    @client.start
  end

  # 停止解析
  def stop
    @stop = true
    if @client
      @client.cancel
    end
  end

  # 重新解析一页
  # @param page Page 页信息
  # @param index int 第几页
  # @param on_complete Callback 回调
  # => 成功: on_complete.inv true, new_page(Page) new_page是新的页数据
  # => 失败: on_complete.inv false
  def reloadPage page, idx, on_complete
    @stop = false
    page.status = 0
    url = page.url
    
    @client = HTTPClient.new page.url
    @client.read_cache = true
    @client.on_complete = Callback.new do |c|
      @client = nil
      if c.getError.length == 0
      	if @duktape == nil
      	  @duktape = DuktapeEngine.new
      	  @duktape.eval file('read.js').text
      	end
      	doc = XMLDocument.new FileData.new(c.path), 1
      	@duktape.eval doc.xpath("//head/script[not(@src)]").first.getContent
      	arr_pages = @duktape.eval('getPages()')
      	n_page = Page.new
      	n_page.status = 1
     	n_page.url = url
        n_page.picture = HOST_URL + arr_pages[idx]
      	on_complete.inv true, n_page
      	
      else
      	on_complete.inv false, page
      end
    end
    @client.start

  end
end
