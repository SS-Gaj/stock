class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  include OverlooksHelper
  include BandsHelper
  before_action :set_datereview

  def hello
    render 'layouts/hello'
  end

private
  def set_datereview
    @date_review ||= Date.yesterday.strftime("%Y-%m-%d") #if Datereview.date_review == nil
#    @date_review ||= Date.today.strftime("%Y-%m-%d")
  end
  
end
