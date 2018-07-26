require 'models'

class Settings < HiEngine::Object
  
  def process
  	item = SettingItem.new
  	item.name = '状态'
  	item.type = 1
  	item.params = [
  		"全部",
  		"连载中",
  		"已完结"
  	]
  	addItem item

  	item = SettingItem.new
  	item.name = '分类'
  	item.type = 1
  	item.params = [
  		"全部",
  		"少年漫画",
  		"少女漫画",
  		"青年漫画"
  	]
  	addItem item

  	item = SettingItem.new
  	item.name = '地域'
  	item.type = 1
  	item.params = [
  		"全部",
  		"日本",
  		"韩国",
  		"欧美",
  		"港台",
  		"内地",
  		"其他"
  	]
  	addItem item

  	item = SettingItem.new
  	item.name = '题材'
  	item.type = 1
  	datas = JSON.parse(file('subject.json').text)
  	item.params = datas.keys
  	addItem item

  	item = SettingItem.new
  	item.name = '排序'
  	item.type = 1
  	item.params = [
  		"按照更新排序",
  		"按照点击排序"
  	]
  	addItem item
  end
end