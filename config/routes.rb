Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root 'application#hello'
  resources :bands do
    get 'newlook', on: :new
    get 'editlook', on: :member
    #get 'savefile', on: :member
  end
  resources :overlooks

end
