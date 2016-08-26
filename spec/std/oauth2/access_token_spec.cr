require "spec"
require "oauth2"

class OAuth2::AccessToken
  describe Bearer do
    it "builds from json" do
      token_value = "some token value"
      token_type = "Bearer"
      expires_in = 3600
      refresh_token = "some refresh token"
      scope = "some scope"
      json = %({
        "access_token" : "#{token_value}",
        "token_type" : "#{token_type}",
        "expires_in" : #{expires_in},
        "refresh_token" : "#{refresh_token}",
        "scope" : "#{scope}"
        })

      access_token = AccessToken.from_json(json)
      access_token = access_token.as(Bearer)
      assert access_token.token_type == "Bearer"
      assert access_token.access_token == token_value
      assert access_token.expires_in == expires_in
      assert access_token.refresh_token == refresh_token
      assert access_token.scope == scope

      access_token = AccessToken::Bearer.from_json(json)
      access_token = access_token.as(Bearer)
      assert access_token.token_type == "Bearer"
      assert access_token.access_token == token_value
      assert access_token.expires_in == expires_in
      assert access_token.refresh_token == refresh_token
      assert access_token.scope == scope
    end

    it "dumps to json" do
      token = Bearer.new("access token", 3600, "refresh token")
      token2 = AccessToken.from_json(token.to_json)
      assert token2 == token
    end

    it "authenticates request" do
      token = Bearer.new("access token", 3600, "refresh token")
      request = HTTP::Request.new "GET", "/"
      token.authenticate request, false
      assert request.headers["Authorization"] == "Bearer access token"
    end
  end

  describe Mac do
    it "builds from json" do
      mac_algorithm = "hmac-sha-256"
      expires_in = 3600
      mac_key = "secret key"
      refresh_token = "some refresh token"
      token_value = "some token value"
      scope = "some scope"
      json = %({
          "token_type": "mac",
          "mac_algorithm": "#{mac_algorithm}",
          "expires_in": #{expires_in},
          "mac_key": "#{mac_key}",
          "refresh_token":"#{refresh_token}",
          "access_token":"#{token_value}",
          "scope":"#{scope}"
        })

      access_token = AccessToken.from_json(json)
      access_token = access_token.as(Mac)
      assert access_token.token_type == "Mac"
      assert access_token.access_token == token_value
      assert access_token.expires_in == expires_in
      assert access_token.refresh_token == refresh_token
      assert access_token.scope == scope
      assert access_token.mac_algorithm == mac_algorithm
      assert access_token.mac_key == mac_key

      access_token = AccessToken::Mac.from_json(json)
      access_token = access_token.as(Mac)
      assert access_token.token_type == "Mac"
      assert access_token.access_token == token_value
      assert access_token.expires_in == expires_in
      assert access_token.refresh_token == refresh_token
      assert access_token.scope == scope
      assert access_token.mac_algorithm == mac_algorithm
      assert access_token.mac_key == mac_key
    end

    it "builds with null refresh token" do
      json = %({
        "token_type": "Mac",
        "access_token":"WRN01OBN1gme8HxeRL5yJ8w05PjCvt-2vXOIle43w9s",
        "expires_in":899,
        "refresh_token":null,
        "mac_algorithm":"hmac-sha-256",
        "mac_key":"N-ATggO2ywqylWgIi3QZn40jWJmL2f9h6ZOGd3jqcxU"
        })
      access_token = AccessToken.from_json(json)
      access_token = access_token.as(Mac)
      assert access_token.refresh_token.nil?
    end

    it "dumps to json" do
      token = Mac.new("access token", 3600, "mac algorithm", "mac key", "refresh token", "scope")
      token2 = AccessToken.from_json(token.to_json)
      assert token2 == token
    end

    it "authenticates request" do
      headers = HTTP::Headers.new
      headers["Host"] = "localhost:4000"

      token = Mac.new("3n2-YaAzH67YH9UJ-9CnJ_PS-vSy1MRLM-q7TZknPw", 3600, "hmac-sha-256", "i-pt1Lir-yAfUdXbt-AXM1gMupK7vDiOK1SZGWkASDc")
      request = HTTP::Request.new "GET", "/some/resource.json", headers
      token.authenticate request, false
      auth = request.headers["Authorization"]
      assert auth =~ /MAC id=".+?", nonce=".+?", ts=".+?", mac=".+?"/
    end

    it "computes signature" do
      mac = Mac.signature 1, "0:1234", "GET", "/resource.json", "localhost", "4000", "", "hmac-sha-256", "i-pt1Lir-yAfUdXbt-AXM1gMupK7vDiOK1SZGWkASDc"
      assert mac == "21vVRFACz5NrO+zlVfFuxTjTx5Wb0qBMfKelMTtujpE="
    end
  end
end
