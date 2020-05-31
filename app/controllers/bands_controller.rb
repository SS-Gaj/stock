class BandsController < ApplicationController
  def index
#		@bands = Band.paginate(page: params[:page])
		@bands = Band.all
  end

  def new #"Обновить" здесь читается сайт reuters по заданным разделам - rtrs_url, и извлекаются анонсы, у которых url содержит шаблон из my_file.
    #Эти анонсы добавляются в БД Band и образуют ленту новостей, которая выводится по пункту меню "Новости" 
    #REUTERS_HOME = 'http://www.reuters.com/'
@bands_last = Band.first
    rtrs_url = [
"https://www.reuters.com/news/archive/hotStocksNews", 
"https://www.reuters.com/news/archive/marketsNews", 
"https://www.reuters.com/news/archive/businessNews", 
"https://www.reuters.com/news/archive/ousivMolt", 
"https://www.reuters.com/news/archive/hongkongMktRpt", 
"https://www.reuters.com/news/archive/londonMktRpt", 
"https://www.reuters.com/news/archive/RCOMUS_Fintech", 
"https://www.reuters.com/news/archive/RCOMUS_Cyberrisk"
]
# https://www.reuters.com/article/china-markets
# 
    rtrs_url.each do |my_url|
      #1 обрабатываем 1-ю страницу
      pastday = DateTime.parse('2017-08-18T04:05:06+03:00')   #просто init
      agent = Mechanize.new
      page = agent.get(my_url)
      pastday = rss_new(page)
      ##1

      #2 цикл для обработки последующих страниц
      target_date = DateTime.now - 2  # сутки назад
      link_next = page.links.find { |l| l.text =~ /Earlier/ }
      until pastday < target_date # если неправда, что время статьи меньше заданного (т.е.если неправда, что статья напечатана раньше, чем заданное время)
        page = link_next.click
        pastday = rss_new(page)
        link_next = page.links.find { |l| l.text =~ /Earlier/ }
        break if link_next == nil
      end # until pastday < target_date
      ##2
    end #rtrs_url.each do |my_url|
    redirect_to bands_path	#bands#index
  end # def new

  def show	#"Просмотреть"
	  @band = Band.find(params[:id])
	  @mas_p = reader(@band.bn_url)
 	  @band.bn_action = 1
 	  @band.save
  end

  def edit	#"Обработать"
	  @band = Band.find(params[:id])
    Obrab.new(editor(@band.bn_url))
#byebug
    if @band.bn_action == 0
     @band.bn_action = 4
    elsif @band.bn_action == 1
      @band.bn_action = 14
    end
 	  @band.save
    #redirect_to new_overlook_path	#overlooks#new
    #redirect_to newlook_new_band	#bands#newlook
    newlook #переход из ленты новостей (Биржи) после нажатия "Обработать"
  	render "newlook"
  end	#def edit	#"Обработать"

def newlook #переход из ленты новостей (Биржи) после нажатия "Обработать"
# создание нового файла "Обзор за ..." или вход в созданный ранее
# + записывание заголовка "Обрабатываемой" статьи и времени публикации
    texttocopy  #/app/controllers/application_controller.rb
  #формирование имени файла "Обзор за ..."
  @preflk = ""
        if @div_isxurl =~ /global/
        @preflk = '/g-lk-'
      elsif @div_isxurl =~ /usa-stocks/
        @preflk = '/lk-'
      elsif @div_isxurl =~ /europe-stocks/
        @preflk = '/lk-'
      elsif @div_isxurl =~ /european-shares/
        @preflk = '/lk-'
      elsif @div_isxurl =~ /europe-stocks/
        @preflk = '/lk-'
      elsif @div_isxurl =~ /japan-stocks/
        @preflk = '/lk-'
      elsif @div_isxurl =~ /hongkong/
        @preflk = '/lk-'
      elsif @div_isxurl =~ /china/
        @preflk = '/lk-'
      elsif @div_isxurl =~ /oil-/
        @preflk = '/o-lk-'
      else
        @preflk = '/lk-'
      end
  target_date = Date.new(DateTime.parse(@div_date).year, DateTime.parse(@div_date).mon, DateTime.parse(@div_date).day)
#  name_lk = dir_save_file(target_date) + name_save_file(target_date, '/lk-', '.xml')  #def dir_save_file и def name_save_file locate in 
        #
  name_lk = dir_save_file(target_date) + name_save_file(target_date, @preflk, '.xml')  #def dir_save_file и def name_save_file locate in 

def editlook	# при нажатии "Copy" во вьюэре
# "Обработываемый" файл открываеся по-новой и считывается в Nokogiri
#номер нужного абзаца выбирается как :id из полученного запроса	
  texttocopy  #  /app/helpers/overlooks_helper.rb
  add_p('/lk-')
	render "newlook"
  #redirect_to :back
end #edit

#byebug
	unless File.exist?(name_lk)
	  unless Overlook.exists?(lk_date: target_date)
      if @preflk == '/g-lk-'
        overlook = Overlook.new(lk_date: target_date, lk_file_g: name_lk)        
      elsif @preflk == '/o-lk-'
        overlook = Overlook.new(lk_date: target_date, lk_file_o: name_lk)                
      else
        overlook = Overlook.new(lk_date: target_date, lk_file: name_lk)        
      end
    else
      overlook = Overlook.find_by lk_date: target_date
      if @preflk == '/g-lk-'
        overlook.lk_file_g  = name_lk
      elsif @preflk == '/o-lk-'
        overlook.lk_file_o  = name_lk
      else
      overlook.lk_file  = name_lk
      end
    end #unless Overlook.exists?(lk_date: target_date)
    overlook.save
		f = File.new(name_lk, 'w')
    @doc_f = Nokogiri::HTML::Document.parse <<-EOHTML
      <root>
        <day>Обзор за </day>
        <newsday>
        </newsday>
        <fullcontent>
        </fullcontent>
      </root>
    EOHTML
    day = @doc_f.at_css "day"
    day.content = "Обзор за " + target_date.strftime("%Y-%m-%d")
    content = @doc_f.at_css "fullcontent"
    content.content = " "
    news = @doc_f.at_css "newsday"
    news.content = " "
    f << @doc_f
    f.close
	end # unless File.exist?(name_lk)

   @doc_f = File.open(name_lk) { |f| Nokogiri::XML(f) }
   f = File.new(name_lk, 'w')
# вставляю @div_first в "newsday"
   newsday = @doc_f.at_css "newsday"
   nodes = @doc_f.css "fullcontent"       # нахожу блок 'fullcontent', поскольку он идет сразу за 'newsday'   
   p = Nokogiri::XML::Node.new "p", @doc_f
   p.content = @div_first
#byebug   
   nodes.first.add_previous_sibling(p)
   p.parent = newsday

# вставляю @div_percent в "newsday"
   newsday = @doc_f.at_css "newsday"
   nodes = @doc_f.css "fullcontent"       # нахожу блок 'fullcontent', поскольку он идет сразу за 'newsday'   
   p = Nokogiri::XML::Node.new "p", @doc_f
   p.content = @div_percent
#byebug   
   nodes.first.add_previous_sibling(p)
   p.parent = newsday
  
    nodes = @doc_f.css "fullcontent"       # а теперь нахожу блок 'fullcontent', чтобы вставить в него Заголовок и дату
# вставляю в "fullcontent" "рамки" для статьи:
    article = Nokogiri::XML::Node.new "article", @doc_f
    article.content = " "
#byebug
    nodes.last.add_next_sibling(article)  
    article.parent = nodes.last

    nodes = @doc_f.css "article"       # нахожу все "article"
    ahead = Nokogiri::XML::Node.new "ahead", @doc_f #создаю узел для заголовка
    ahead.content = @div_article_header
    nodes.last.add_next_sibling(ahead)
    ahead.parent = nodes.last #article

    nodes = @doc_f.css "article"       # ЯтД, что узел поменялся, поэтому создаю его заново
    atime = Nokogiri::XML::Node.new "atime", @doc_f
    atime.content = @div_date
    nodes.last.add_next_sibling(atime)
    atime.parent = nodes.last #article

    f << @doc_f
		f.close
#byebug
end #def new #переход из ленты новостей после нажатия "Обработать"


  private
  	  def my_file (mas)
      need_file = false
      @btc_file = false      
	    if mas =~ /usa-stocks/
	      need_file = true
	    elsif mas =~ /global-markets/
	      need_file = true
	    elsif mas =~ /japan-stocks/
	      need_file = true
	    elsif mas =~ /stocks-hongkong/
	      need_file = true
	    elsif mas =~ /china-stocks-close/
	      need_file = true
	    elsif mas =~ /china-stocks-midday/
	      need_file = true
	    elsif mas =~ /china-markets/
	      need_file = true
	    elsif mas =~ /china-stocks-hongkong-close/
	      need_file = true
	    elsif mas =~ /china-stocks-hongkong-close/
	      need_file = true
	    elsif mas =~ /europe-stocks/
	      need_file = true
	    elsif mas =~ /bitcoin/
	      need_file = true
	      @btc_file = true
	    elsif mas =~ /virtual-currenc/
	      need_file = true
	      @btc_file = true
	    elsif mas =~ /blockchain/
	      need_file = true
	      @btc_file = true
	    elsif mas =~ /cryptocurrency/
	      need_file = true
	      @btc_file = true
	    elsif mas =~ /opec|oil/
	      need_file = true
	    else
	    end
	    return need_file
	  end # def my_file (mas)

    def rss_new(page)
      doc = Nokogiri::HTML(page.body)
      div_block_article = doc.css("div[class=story-content]")
      div_block_article.each do |link|
        href_view = link.css("a").first['href']
## unless href_view =~ /idUSL8N1W4203/   #не найду причину ошибки, поэтому убираю конкретную статью - см.hm-pisma26-180918(time-err)
        name_view = link.css("h3").first.text.strip
        time_view = link.css("time[class=article-time]").css("span[class=timestamp]").first
unless time_view == nil
#byebug        
        @time_view = time_view.text
        content_view = link.css("p").first.text.strip
        if my_file(href_view)
            band = Band.new(bn_head: name_view, novelty: content_view, 
            bn_date: @time_view, bn_url: href_view, bn_action: 0)
            band.save
        end #if my_file(href_view)
end #time_view == nil
      end #div_block_article.each do |link|
      return DateTime.parse(@time_view)   
##end #unless href_view =~ /idUSL8N1W4203/
    end #rss_new
    
  def add_p(dir_lk) #добавить вбзац
  #номер нужного абзаца выбирается как :id из полученного запроса	
    target_date = Date.new(DateTime.parse(@div_date).year, DateTime.parse(@div_date).mon, DateTime.parse(@div_date).day)
    name_lk = dir_save_file(target_date) + name_save_file(target_date, dir_lk, '.xml')  #def dir_save_file и def name_save_file locate in 
	  if File.exist?(name_lk)
     @doc_f = File.open(name_lk) { |f| Nokogiri::XML(f) }
     nodes = @doc_f.css "ahead, atime, p"
     f = File.new(name_lk, 'w')
      p = Nokogiri::XML::Node.new "p", @doc_f
      p.content = @mas_p[params[:id].to_i]
      nodes.last.add_next_sibling(p)
      f << @doc_f   
		  f.close
	  end # if File.exist?(name_lk)
  end #add_p

end
