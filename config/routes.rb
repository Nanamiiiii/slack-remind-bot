Rails.application.routes.draw do
    get "/"=>"slack#index"
    post "/commands"=>"slack#commands"
    post "/interact"=>"slack#interact"
end
