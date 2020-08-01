class BandsController < ApplicationController
  def index
#byebug
    if params[:query] == "0"
      @bands = Band.where("bn_action >= '0'").page(params[:page]).order('bn_date DESC')
    else
      @bands = Band.where("bn_action < '0'").page(params[:page]).order('bn_date DESC')
    end #if params[:query]

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
    redirect_to action: "index", query: "0"	#bands#index
  end # def new

  def show	#"Просмотреть"
	  @band = Band.find(params[:id])
	  @mas_p = reader(@band.bn_url)
	  if @band.bn_action == 0
   	  @band.bn_action = 1
    elsif @band.bn_action == 4
      @band.bn_action = 14
    end
 	  @band.save
  end

  def edit	#"Обработать"
	  @band = Band.find(params[:id])
    if @band.bn_action == 0
     @band.bn_action = 4
    elsif @band.bn_action == 1
      @band.bn_action = 14
    elsif @band.bn_action == 5
      @band.bn_action = 45
    end
 	  @band.save
 	  @mas_p = reader(@band.bn_url)  
#здесь @mas_p не МАССИВ ПАРАГРАФОВ <p>...</p>, а ВСЯ html-переменная "Обрабатываемого" файла!!!!  
    @var_html = toobrab(@band.bn_url, @mas_p)
    @var_html_class = Obrab.new(@var_html)
    @teg_to_copy = 'global'
    @var_teg = Tegiobrab.new(@teg_to_copy)
    newlook #Это бывший (в /pisma) #overlooks#new
  	render "newlook"
  end	#def edit	#"Обработать"

  def radiomenu #Выбот тега для "Copy" в заданный раздел
    @teg_to_copy = params[:inlineRadioOptions]
    @var_teg = Tegiobrab.new(@teg_to_copy)  
  end

  def datereview #Установка даты для файла "Обработать"
    @date_review = params[:datereview]
    @var_datereview = Datereview.new(@date_review)
  end

def newlook #С 12чер20 здесь .html вместо .xml
# создание нового файла "Обзор за ..." или вход в созданный ранее
# + записывание заголовка "Обрабатываемой" статьи и времени публикации
#    texttocopy  #/app/controllers/application_controller.rb
  #формирование имени файла "Обзор за ..."
  @preflk = '/lk-'
  @date_review = Datereview.date_review
  target_date = Date.parse(@date_review)
  name_lk = dir_save_file(target_date) + name_save_file(target_date, @preflk, '.html')  #def dir_save_file и def name_save_file locate in 
	unless File.exist?(name_lk)
	  unless Overlook.exists?(lk_date: target_date)
        overlook = Overlook.new(lk_date: target_date, lk_file: name_lk)        
    else
      overlook = Overlook.find_by lk_date: target_date
      overlook.lk_file  = name_lk
    end #unless Overlook.exists?(lk_date: target_date)
    overlook.save
		f = File.new(name_lk, 'w')
#    @doc_f = Nokogiri::HTML::DocumentFragment.parse <<-EOHTML 
    @doc_f = Nokogiri::HTML::Document.parse <<-EOHTML
    <!DOCTYPE html>
      <html>
        <head>
          <title>Reuters|Обзор</title>
        </head>
          <body>
            <h1>Обзор за </h1>
            <div class="article">
              <div class="global">
                <h3>Глобал</h3>
                <p></p>
              </div>
              <div class="index">
                <h3>Индексы</h3>
                <p></p>
              </div>
              <div class="asia">
                <h3>Азия</h3>
                <p></p>
              </div>
              <div class="euro">
                <h3>Европа</h3>
                <p></p>
              </div>
              <div class="usa">
                <h3>США</h3>
                <p></p>
              </div>
              <div class="forex">
                <h3>Forex</h3>
                <p></p>
              </div>
              <div class="company">
                <h3>Корпоративные новости</h3>
                <p></p>
              </div>
              <div class="oil">
                <h3>Нефть</h3>
                <p></p>
              </div>
            </div>
          </body>
      </html>
    EOHTML
    day = @doc_f.at_css "h1"
    day.content = "Обзор за " + target_date.strftime("%Y-%m-%d")
    @doc_f.to_html
    f << @doc_f
    f.close
	end # unless File.exist?(name_lk)
end #def newlook #С 12чер20 здесь .html вместо .xml

def editlook	# при нажатии "Copy" во вьюэре
  texttocopy  #Здесь восстанавливается .html-переменная "Обрабатываемого" файла из class Obrab;
#... и там же номер нужного абзаца выбирается как :id из полученного запроса	
  add_p('/lk-')
	render "newlook"
  #redirect_to :back
end #edit

  def corect #"Корр.время" 
  	  @band = Band.find(params[:id])
   	  @band.bn_date = @band.bn_date - 86400
  	  @band.save
  	  redirect_to action: "index", query: "0"	#bands#index
  end # def destroy

  def savefile	#“Save-file-txt”
 	  @band = Band.find(params[:id])
    if @band.bn_action == 0
      @band.bn_action = 5
    elsif @band.bn_action == 1
      @band.bn_action = 15
    elsif @band.bn_action == 4
      @band.bn_action = 45
    elsif @band.bn_action == 14
      @band.bn_action = 145
    end
 	  @band.save
    wrieter(@band.bn_url)      
    redirect_to action: "index", query: "0"	#bands#index
  end	#def savefile	#“Save-file-txt”

  def hide	#“Скрыть”
 	  @band = Band.find(params[:id])
 	  @band.bn_action = -1
 	  @band.save
    redirect_to action: "index", query: "0"
  end	#def hide	#“Скрыть”


  private
    def rtdatefile(url_date)
      return DateTime.parse(url_date).strftime("%y%m%d") + '-' + DateTime.parse(url_date).strftime("%H%M") + '.txt'           
    end

  def wrieter(url_article)  #“Save-file-txt”
    target_date = DateTime.parse('2017-09-23T04:05:06+03:00')   #просто init
    article = reader(url_article)
    target_date = Date.new(DateTime.parse(@div_date).year, DateTime.parse(@div_date).mon, DateTime.parse(@div_date).day)
    name_file = dir_save_file(target_date) + '/bn-' + name_need_file(url_article) + rtdatefile(@div_date)
  city = ""
  unless File.exist?(name_file)
		f = File.new(name_file, 'w')
	  f << "http://www.reuters.com" + url_article + "\n\n\n"
	  f << @div_article_header + "\n"
	  f << @div_date + "\n"

    article.each do |elem|
	    f << elem + "\n"
        if city == ""
          if elem =~ /TOKYO/
            city = 'TOKYO'
          elsif elem =~ /LONDON/
            city = 'LONDON'
          elsif elem =~ /YORK/
            city = 'YORK'
          elsif elem =~ /SYDNEY/
            city = 'SYDNEY'
          end
        end
      end # article.each do |elem|
		f.close
    old_name = String.new(name_file)
    new_name = name_file.insert(name_file.index('.txt'), city)
    File.rename(old_name, new_name)  if city != ""

	  end # unless File.exist?(name_file)
  end #  def wrieter(url_article)  #“Save-file-txt”

  def reader(url_article) #для "Просмотреть"
    agent = Mechanize.new
    page = agent.get("http://www.reuters.com" + url_article)    #@band.bn_url
    doc = Nokogiri::HTML(page.body)
    div_all_page = doc.css("div[class=StandardArticle_inner-container]")
    @div_article_header = div_all_page.css("div[class=ArticleHeader_content-container] h1").text
    @div_date = div_all_page.css("div[class=ArticleHeader_content-container]").css("div[class=ArticleHeader_date]").text
    @div_isxurl = url_article
    unless url_article =~ /live-markets/
      article = div_all_page.css("div[class=StandardArticleBody_body] p")
    else
      article = div_all_page.css("div [class=StandardArticleBody_body_1gnLA] pre")
    end
    mas_glob = []
    article.each do |elem|
      elem = elem.text.gsub("\n", " ")
      if elem.include? "**"
        mas = []
        mas = elem.split('**')
        mas.each do |star|
          mas_glob.push(star) unless star == ""
        end
      else
        mas_glob.push(elem)
      end   #if @div_first.include? "**"
    end #article.each do |elem|
    return mas_glob 
  end #def reader(url_article) #для "Прочитать"

  def toobrab(url_article, article)
    f = String.new
    f << "<!DOCTYPE html>"
    f << "<html>"
    f << "<head>"
    f << "<title>Reuters | Обработать</title>"
    f << "</head>"
    f << "<body>"
    f << "<h3>" + @div_article_header + "</h3>"
    f << "<h3>" + @div_date + "</h3>"
    f << "<h4>" + url_article + "</h4>"
    article.each do |elem|
      mas = []
      mas = elem.split('**')
      mas.each do |para|
	      f << "<p>" + para + "</p>"
	    end #mas.each do |para|
    end # article.each do |elem|
    f << "</body>"
    f << "</html>"
    return f
  end #def toobrab (url_article, sfera, article)

  def texttocopy()
  # "Обработываемый" файл был сохранен как .html-переменная в class Obrab и здесь восстанавливается по-новой
  #... и считывается в Nokogiri
    doc_obrab = Nokogiri::HTML(Obrab.file_obrab)
    div_all_page = doc_obrab.css("html")
    article = div_all_page.css("h3")
    @div_article_header = article.first.text
    @div_date = article.last.text
    @div_isxurl = div_all_page.css("h4").text
    div_h5 = div_all_page.css("h5")
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
	    elsif url =~ /britain/
	      name_file = 'britain-'
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
	  dir_year = date_prezent.year.to_s
	  dir_mon = date_prezent.mon.to_s
	  dir_day = date_prezent.day.to_s
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
	    elsif mas =~ /britain/
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
        name_view = link.css("h3").first.text.strip
        time_view = link.css("time[class=article-time]").css("span[class=timestamp]").first
unless time_view == nil
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
    end #rss_new
    
  def add_p(dir_lk) #добавить абзац
  #номер нужного абзаца выбирается как :id из полученного запроса	
    @date_review = Datereview.date_review
    target_date = Date.parse(@date_review)
    name_lk = dir_save_file(target_date) + name_save_file(target_date, dir_lk, '.html')  #def dir_save_file и def name_save_file locate in 
	  if File.exist?(name_lk)
     @doc_f = File.open(name_lk) { |f| Nokogiri::XML(f) }
     @teg_to_copy = Tegiobrab.name_teg
     if @teg_to_copy == 'global'
       div_class = @doc_f.css "div[class=global]"
     elsif @teg_to_copy == 'index'
         div_class = @doc_f.css "div[class=index]"
     elsif @teg_to_copy == 'asia'
         div_class = @doc_f.css "div[class=asia]"
     elsif @teg_to_copy == 'euro'
         div_class = @doc_f.css "div[class=euro]"
     elsif @teg_to_copy == 'usa'
         div_class = @doc_f.css "div[class=usa]"
     elsif @teg_to_copy == 'forex'
         div_class = @doc_f.css "div[class=forex]"
     elsif @teg_to_copy == 'company'
         div_class = @doc_f.css "div[class=company]"
     elsif @teg_to_copy == 'oil'
         div_class = @doc_f.css "div[class=oil]"
     else
         div_class = @doc_f.css "div[class=global]"
     end
     div_p = div_class.css "p"
     f = File.new(name_lk, 'w')
      new_p = Nokogiri::XML::Node.new "p", @doc_f
      new_p.content = @mas_p[params[:id].to_i]
      div_p.last.add_next_sibling(new_p)
      @doc_f.to_html
      f << @doc_f   
		  f.close
	  end # if File.exist?(name_lk)
  end #add_p

end
