Rails.application.routes.draw do
  get "/"=>"slack#index"
  post "/receive"=>"slack#create"
  post "/commands"=>"slack#commands"
end
