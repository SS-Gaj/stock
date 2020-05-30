class OverlooksController < ApplicationController
  def index
    @overlooks = Overlook.paginate(page: params[:page])
  end

def new #переход из ленты новостей (Биржи) после нажатия "Обработать"
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

def edit	# при нажатии "Copy"
# "Обработываемый" файл открываеся по-новой и считывается в Nokogiri
#номер нужного абзаца выбирается как :id из полученного запроса	
  texttocopy  #  /app/helpers/overlooks_helper.rb
  add_p('/lk-')
	render "new"
  #redirect_to :back
end #edit

  def show  #кнопка "Просмотреть" из страницы "Обзор за..."
    @overlook = Overlook.find(params[:id])
    name_lk = @overlook.lk_file
    if File.exist?(name_lk)
      @doc_f = File.open(name_lk) { |f| Nokogiri::XML(f) }
      @newsday_mas = @doc_f.css "newsday p"
      @article_mas = @doc_f.css "fullcontent article"
#      @article_mas = @doc_f.css "fullcontent" #"article"
    end # if File.exist?(name_lk)
  end #show
  
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

private
    def set_preflk
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
    end

end
