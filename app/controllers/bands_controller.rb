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

end
