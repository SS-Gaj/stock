Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root 'application#hello'
  resources :bands do
    get 'newlook', on: :new
    get 'radiomenu', on: :new
    get 'datereview', on: :new
    get 'editlook', on: :member
    get 'savefile', on: :member
    get 'corect', on: :member
    get 'hide', on: :member
  end
  resources :overlooks

end
