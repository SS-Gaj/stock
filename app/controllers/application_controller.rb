class ApplicationController < ActionController::Base
protect_from_forgery with: :exception
  def hello
    render 'layouts/hello'
  end
  
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

end
