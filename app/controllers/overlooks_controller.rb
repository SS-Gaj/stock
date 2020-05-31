class OverlooksController < ApplicationController
  def index
    @overlooks = Overlook.paginate(page: params[:page])
  end

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
  
private

end
