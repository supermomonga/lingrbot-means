require 'json'

def create_message_json(text)
  body = { "events" => [ { "message" => { "text" => text, "room" => "imascg", "nickname" => "joe" } } ] }
  body.to_json.to_s
end
