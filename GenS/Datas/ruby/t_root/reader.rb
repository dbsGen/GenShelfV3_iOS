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
  HOST_URL = 'http://i.hamreus.com:8080'
  @stop = false
  @chapter_url
  @duktape = nil

  def comic_url
    host = case settings.find('服务器')
    when 0
      "comic"
    when 1
      "comic2"
    when 2
      "comic3"
    else
      "comic"
    end
    "http://#{host}.kukudm.com"
  end

  def load_book url, index, total, on_complete = nil
    @client = HTTPClient.new url
    @client.delay = 0.5
    @client.read_cache = true
    @client.on_complete = Callback.new do |c|
      @client = nil
      if c.getError.length == 0
        doc = XMLDocument.new FileData.new(c.path), 1
        if total == 0
          node = doc.xpath("//*[@id='page1']/preceding-sibling::text()").first
          node.getContent[/共(\d+)页/]
          total = $1.to_i
          on_page_count.inv true, total
        end
        ss = doc.xpath "//head/script"
        unless @duktape
            @duktape = DuktapeEngine.new
            @duktape.eval "var document = {};document.write = function(input) {return input;}"
            @duktape.eval "var window = this;window.setTimeout = function(){}"
        end
        load_script ss, 0 do
          script_ndoe = doc.xpath("//script[not(@src)]").first
          res = @duktape.eval script_ndoe.getContent
          s_doc = XMLDocument.new Data::fromString(res), 1
          img = s_doc.getRoot.xpath('//img').first
          page = Page.new
          page.status = 1
          page.url = url
          page.picture = @duktape.eval("encodeURI(\"#{img.attr 'src'}\")")
          
          if on_complete
            on_complete.call true, page
          else
            loadedPage index, true, page
            if index + 1 < total
              next_node = doc.xpath("//a/img[@src='/images/d.gif']/..").first
              load_book comic_url+next_node.attr('href'), index + 1, total
            end
          end
        end
      else
        if on_complete
          on_complete.call false
        else
          if total == 0
            on_page_count.inv false
          end
        end
      end
    end
    @client.start
    @client
  end

  def load_script scripts, index, &block
    if index < scripts.size
      src = comic_url + scripts[index].attr('src')
      @client = HTTPClient.new src
      @client.read_cache = true
      @client.on_complete = Callback.new do |c|
        if c.getError.length == 0
          @duktape.eval Encoder::decode(FileData.new(c.path), "gbk")
          load_script scripts, index + 1, &block
        else
          on_page_count.inv false
        end
      end
      @client.start
    else
      block.call
    end
  end

  # 开始解析一个章节，读取其中所有的页
  # @param chapter Chapter 章节信息
  def process chapter
    @chapter_url = chapter.url
    @stop = false

    load_book @chapter_url, 0, 0
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
    
    block = Proc.new do |success, n_page|
      if success
        on_complete.inv true, n_page
      else
        on_complete.inv false, page
      end
    end
    load_book page.url, 0, 0, block
  end
end
