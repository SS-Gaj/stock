class BandsController < ApplicationController
  def index
#		@bands = Band.paginate(page: params[:page])
#		@bands = Band.paginate(page: params[:page], per_page: 30)
    @bands = Band.page(params[:page]).order('bn_date DESC')
#		@bands = Band.all
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
    newlook #Это бывший (в /pisma) #overlooks#new
  	render "newlook"
  end	#def edit	#"Обработать"

def newlook #Это бывший (в /pisma) #overlooks#new
# создание нового файла "Обзор за ..." или вход в созданный ранее
# + записывание заголовка "Обрабатываемой" статьи и времени публикации
    texttocopy  #/app/controllers/application_controller.rb
  #формирование имени файла "Обзор за ..."
  @preflk = '/lk-'
  target_date = Date.new(DateTime.parse(@div_date).year, DateTime.parse(@div_date).mon, DateTime.parse(@div_date).day)
#  name_lk = dir_save_file(target_date) + name_save_file(target_date, '/lk-', '.xml')  #def dir_save_file и def name_save_file locate in 
        #
  name_lk = dir_save_file(target_date) + name_save_file(target_date, @preflk, '.xml')  #def dir_save_file и def name_save_file locate in 

#byebug
	unless File.exist?(name_lk)
	  unless Overlook.exists?(lk_date: target_date)
        overlook = Overlook.new(lk_date: target_date, lk_file: name_lk)        
    else
      overlook = Overlook.find_by lk_date: target_date
      overlook.lk_file  = name_lk
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

def editlook	# при нажатии "Copy" во вьюэре
# "Обработываемый" файл открываеся по-новой и считывается в Nokogiri
#номер нужного абзаца выбирается как :id из полученного запроса	
  texttocopy  #  /app/helpers/overlooks_helper.rb
  add_p('/lk-')
	render "newlook"
  #redirect_to :back
end #edit


  private
  
  def reader(url_article) #для "Просмотреть"
    agent = Mechanize.new
    page = agent.get("http://www.reuters.com" + url_article)    #@band.bn_url
    doc = Nokogiri::HTML(page.body)
    div_all_page = doc.css("div[class=StandardArticle_inner-container]")
    @div_article_header = div_all_page.css("div[class=ArticleHeader_content-container] h1").text
    @div_date = div_all_page.css("div[class=ArticleHeader_content-container]").css("div[class=ArticleHeader_date]").text
    unless url_article =~ /live-markets/
      article = div_all_page.css("div[class=StandardArticleBody_body] p")
    #byebug
    else
      article = div_all_page.css("div [class=StandardArticleBody_body_1gnLA] pre")
    end    
    mas_glob = []
    article.each do |elem|
     mas_glob.push(elem.text.gsub("\n", " "))
    end
    mas_glob.each do |first|
      if first =~ /\(Reuters\)/
        @div_first = first
        break
      end # if first =~ /\(Reuters\)/
    end   # mas_glob.each do |first|
    mas_glob.each do |first|
      if first =~ /percent(,*)\s(\w*\s)*(\d)+,\d\d\d.\d/
        @div_percent = first
        break
      end # if first =~ /\(Reuters\)/
    end   # mas_glob.each do |first|
    mas_glob.each do |first|
      if first =~ /STOXX/ and first =~ /percent/
        @div_percent = first
        break
      end # if first =~ /\(Reuters\)/
    end   # mas_glob.each do |first|
    if @div_first == nil
      @div_first = " "
    else
    ### для "китайцев" НАЧАЛО
    if @div_first.include? "**"
      mas = @div_first.split('**')
      mas.each do |first|
       if first =~ /\(Reuters\)/
        @div_first = first
        break
       end
      end   #mas.each do |first|
    end # if @div_first.include? "**"
    @div_first = @div_first + " /" + @div_date +"/"
    end # if @div_first.include? "**"
    #@div_percent = " " if @div_percent == nil    
    if @div_percent == nil
      @div_percent = " "
    else
      if @div_percent.include? "**"
        mas = @div_percent.split('**')
        mas.each do |first|
         if first =~ /percent(,*)\s(\w*\s)*(\d)+,\d\d\d.\d/
          @div_percent = first
          break
         end
        end   #mas.each do |first|
      end # if @div_first.include? "**"
    end   # if @div_percent == nil
### для "китайцев" КОНЕЦ
    return mas_glob 
  end #def reader(url_article) #для "Прочитать"

  def editor(url_article) #"Обработать"
    article = reader(url_article)  
    name_file = toobrab(url_article, 'obrab', article)
    return name_file
  end #editor #"Обработать"

  def toobrab(url_article, sfera, article)
      target_date = DateTime.parse('2017-09-23T04:05:06+03:00')   #просто init
    target_date = Date.new(DateTime.parse(@div_date).year, DateTime.parse(@div_date).mon, DateTime.parse(@div_date).day)
    name_file = dir_save_file(target_date)
    Dir.mkdir(sfera) unless File.directory?(sfera)
	  Dir.chdir(sfera)
    name_file = name_file + '/' + sfera + '/' + name_need_file(url_article)
    if id_name = url_article =~ /id[A-Z\d]+\Z/ #/id/
      name_file = name_file + url_article[id_name, url_article.length-id_name]
    else
      name_file = name_file + 'id_no'    
    end 
    name_file = name_file + '.html'
  #unless File.exist?(name_file)
  	f = File.new(name_file, 'w') 
    f << "<!DOCTYPE html>"
    f << "<html>"
    f << "<head>"
    f << "<title>Reuters | Обработать</title>"
    f << "</head>"
    f << "<body>"
    f << "<h3>" + @div_article_header + "</h3>"
    f << "<h3>" + @div_date + "</h3>"
    f << "<h4>" + url_article + "</h4>"
    #byebug
    f << "<h5>" + @div_first + "</h5>"
    f << "<h5>" + @div_percent + "</h5>"
    article.each do |elem|
      mas = []
      mas = elem.split('**')
      mas.each do |para|
	      f << "<p>" + para + "</p>"
	    end #mas.each do |para|
    end # article.each do |elem|
    f << "</body>"
    f << "</html>"
	  # start save file
		f.close
    return name_file
  end #def toobrab (url_article, sfera, article)

  def texttocopy()
  # "Обработываемый" файл открываеся по-новой и считывается в Nokogiri
  #byebug
    @file_obrab = Obrab.file_obrab  # Obrab получил на хранение "имя файла" в bands_controller.rb
    doc_obrab = File.open(@file_obrab) { |f| Nokogiri::XML(f) }
    div_all_page = doc_obrab.css("html")
    article = div_all_page.css("h3")
    @div_article_header = article.first.text
    @div_date = article.last.text
    @div_isxurl = div_all_page.css("h4").text
#    @div_first = div_all_page.css("h5").text
    div_h5 = div_all_page.css("h5")
    @div_first = div_h5.first.text
    @div_percent = div_h5.last.text
    #@div_first = " "    #это временная мера, см.п.18.1 hm-news_day-180331(console-21)
    article = div_all_page.css("p")
    @mas_p = []
    article.each do |elem|
      @mas_p.push(elem.text.gsub("\n", " "))
    end
  end # def texttocopy()

      def name_need_file (url) # used hier
      if url =~ /bitcoin/
        name_file = 'bitcoin-'
      elsif url =~ /usa-stocks/
        name_file = 'usa-'
      elsif url =~ /global-markets/
        name_file = 'global-'
      elsif url =~ /japan-stocks/
        name_file = 'japan-'
      elsif url =~ /hongkong/
        name_file = 'hongkong-'
      elsif url =~ /china/
        name_file = 'china-'
      elsif url =~ /europe-stocks/
        name_file = 'europe-'
      elsif url =~ /european-shares/
        name_file = 'europe-'
      elsif url =~ /oil-/
        name_file = 'oil-'
      else
        name_file = 'othe-'
      end
      if url =~ /midday/
        name_file = name_file + 'midday-'
      elsif url =~ /close/
        name_file = name_file + 'close-'
      else
      end
      return name_file
    end	#name_need_file

  def dir_save_file (date_prezent)  # used in overlooks_controller.rb
  # puts "REUTERS_DIR = #{REUTERS_DIR}"
	  dir_year = date_prezent.year.to_s
	  dir_mon = date_prezent.mon.to_s
	  dir_day = date_prezent.day.to_s
	  #Dir.chdir(REUTERS_DIR)
	  #REUTERS_DIR = '/home/ss/Documents/Reuters/index'
	  #Dir.chdir('/home/ss/Documents/Reuters')
    Dir.chdir('/home/ss/reuters')
	  Dir.mkdir(dir_year) unless File.directory?(dir_year)
	  Dir.chdir(dir_year)
	  Dir.mkdir(dir_mon) unless File.directory?(dir_mon)
	  Dir.chdir(dir_mon)
	  Dir.mkdir(dir_day) unless File.directory?(dir_day)
	  Dir.chdir(dir_day)
	  return Dir.pwd
  end	#my_dir
  
  def name_save_file (date_prezent, prefix, type) # used in overlooks_controller.rb and reviews_controller.rb
    return  prefix + date_prezent.strftime("%y%m%d") + type #'/lk-' '.xml'
  end	#my_file

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
