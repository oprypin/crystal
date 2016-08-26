require "spec"
require "oauth"

describe OAuth::AccessToken do
  it "creates from response body" do
    access_token = OAuth::AccessToken.from_response("oauth_token=1234-nyi1G37179bVdYNZGZqKQEdO&oauth_token_secret=f7T6ibH25q4qkVTAUN&user_id=1234&screen_name=someuser")
    assert access_token.token == "1234-nyi1G37179bVdYNZGZqKQEdO"
    assert access_token.secret == "f7T6ibH25q4qkVTAUN"
    assert access_token.extra["user_id"] == "1234"
    assert access_token.extra["screen_name"] == "someuser"
  end
end
