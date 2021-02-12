module Client
    class PortalClient
        AUTH_TOKEN = ENV['PORTAL_AUTH_TOKEN']

        def initialize()
            @cli = Faraday::Connection.new(:url => 'https://portal.misw.jp') do |builder|
                builder.use Faraday::Request::UrlEncoded
                builder.use Faraday::Response::Logger
                builder.response :json, :content_type => /\bjson$/
                builder.adapter Faraday::Adapter::NetHttp
            end
        end

        def check_user_role(user_id)
            response = @cli.get '/api/external/find_role' do |req|
                req.headers["Authorization"] = AUTH_TOKEN
                req.params[:slack_id] = user_id
            end

            puts response

            return response.body["role"]
        end
    end
end