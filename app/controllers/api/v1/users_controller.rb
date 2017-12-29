class Api::V1::UsersController < ApplicationController
  def create
    body = {
      grant_type: "authorization_code",
      code: params[:code],
      redirect_uri: ENV["REDIRECT_URI"],
      client_id: ENV["CLIENT_ID"],
      client_secret: ENV["CLIENT_SECRET"]
    }

    auth_response = RestClient.post("https://accounts.spotify.com/api/token", body)
    auth_params = JSON.parse(auth_response.body)

    header = {
      Authorization: "Bearer #{auth_params["access_token"]}"
    }

    user_response = RestClient.get('https://api.spotify.com/v1/me', header)
    user_params = JSON.parse(user_response.body)

    binding.pry

    @user = User.find_or_create_by(
      username: user_params["id"],
      display_name: user_params["display_name"],
      spotify_url: user_params["external_urls"]["spotify"],
      href: user_params["href"],
      uri: user_params["uri"]
    )

    payload = {:access_token => auth_params["access_token"]}
    token = JWT.encode(payload, ENV["MY_SECRET"], ENV["EGGS"])
    refresh_payload = {:refresh_token => auth_params["refresh_token"]}
    refresh_token = JWT.encode(refresh_payload, ENV["MY_SECRET"], ENV["EGGS"])

    @user.update(
      access_token: token,
      refresh_token: refresh_token
    )

    jwt_payload = {:user_id => @user.id}
    jwt = JWT.encode(jwt_payload, ENV["MY_SECRET"], ENV["EGGS"])
    serialized_user = UserSerializer.new(@user).attributes
    render json: {currentUser: serialized_user, code: jwt}
  end

  def show
    encrypted_user_id = params["jwt"]
    user_id = JWT.decode(encrypted_user_id, ENV["MY_SECRET"], ENV["EGGS"])
    @user = User.find_by(id: user_id[0]["user_id"])

    jwt_payload = {:user_id => @user.id}
    jwt = JWT.encode(jwt_payload, ENV["MY_SECRET"], ENV["EGGS"])
    serialized_user = UserSerializer.new(@user).attributes
    render json: {currentUser: serialized_user, code: jwt}
  end

end
