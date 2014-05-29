q = require('q')
_ = require('underscore')
https = require('https')

key_token = 'WITBOT_ACCESS_TOKEN'

wit_hostname = "https://api.wit.ai"
wit_msg_path = (msg) -> "#{wit_hostname}/message?q=#{msg}"
wit_access_token = process.env[key_token] || throw new Error("Couldn't read env #{key_token}")

inspect = (x) ->
  JSON.stringify(x, null, 2)

send_to_wit = (robot, msg) ->
  def = q.defer()

  robot
  .http(wit_msg_path(msg))
  .header('authorization', "Bearer #{wit_access_token}")
  .get() (err, res, body) ->
    if err
      def.reject(err)
      return

    def.resolve(JSON.parse(body))

  return def.promise

rand = (ary) ->
  _(ary).shuffle()[0]

no_idea = ->
  rand([
    "No idea what you're saying",
    "Did not catch that",
    "Sorry, what?"
  ])

hello = ->
  rand([
    "Hello to you!",
    "Howdy!",
    "안녕!"
  ])

dont_know_this_function = ->
  "Don't know this function!"

command_for = (f) ->
  if /deploy/i.test f
    "ansible-playbook -i ansible/digital_ocean_hosts ansible/deploy-wit-jar.yml"
  else if /fun/i.test f
    "cowsay -f dragon 'Wit rocks!'"
  else
    dont_know_this_function()

module.exports = (robot) ->
  robot.respond /wit (.*)/, (msg) ->
    body = msg.match[1]

    send_to_wit(robot, body).then (w) ->
      # msg.send inspect(w)
      resp = switch w.outcome.intent
        when "hello"
          hello()
        when "what_command"
          if f = w.outcome.entities.function
            command_for(f.value)
          else
            dont_know_this_function()
        else
          no_idea()

      msg.send resp
    , (err) ->
      msg.send inspect(err)
