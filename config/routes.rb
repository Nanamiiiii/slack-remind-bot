Rails.application.routes.draw do
  get "/"=>"slack#index"
  post "/receive"=>"slack#create"
end
