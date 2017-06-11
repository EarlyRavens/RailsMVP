Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  resources :search#, only: [:index, :show, :create]
  get 'query', to: 'search#query'

  root 'search#index'


end
