class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  include OverlooksHelper
  include BandsHelper

  def hello
    render 'layouts/hello'
  end

end
