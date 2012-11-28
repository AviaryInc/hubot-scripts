# Description:
#   Track arbitrary karma
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   <thing>++ - give thing some karma
#   <thing>-- - take away some of thing's karma
#   hubot karma <thing> - check thing's karma (if <thing> is omitted, show the top 5)
#   hubot karma empty <thing> - empty a thing's karma
#   hubot karma best - show the top 5
#   hubot karma worst - show the bottom 5
#
# Author:
#   stuartf

htmlEscape = (html) ->
  return String(html).replace(/&(?!\w+;)/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;')

class Karma
  
  constructor: (@robot) ->
    @cache = {}
    
    @increment_responses = [
      "+1!", "gained a level!", "is on the rise!", "leveled up!"
    ]
  
    @decrement_responses = [
      "took a hit! Ouch.", "took a dive.", "lost a life.", "lost a level."
    ]
    
    @robot.brain.on 'loaded', =>
      if @robot.brain.data.karma
        @cache = @robot.brain.data.karma
  
  kill: (thing) ->
    delete @cache[thing]
    @robot.brain.data.karma = @cache
  
  increment: (thing) ->
    @cache[thing] ?= 0
    @cache[thing] += 1
    @robot.brain.data.karma = @cache

  decrement: (thing) ->
    @cache[thing] ?= 0
    @cache[thing] -= 1
    @robot.brain.data.karma = @cache
  
  incrementResponse: ->
     @increment_responses[Math.floor(Math.random() * @increment_responses.length)]
  
  decrementResponse: ->
     @decrement_responses[Math.floor(Math.random() * @decrement_responses.length)]

  get: (thing) ->
    k = if @cache[thing] then @cache[thing] else 0
    return k

  sort: ->
    s = []
    for key, val of @cache
      s.push({ name: key, karma: val })
    s.sort (a, b) -> b.karma - a.karma
  
  top: (n = 5) ->
    sorted = @sort()
    sorted.slice(0, n)
    
  bottom: (n = 5) ->
    sorted = @sort()
    sorted.slice(-n).reverse()
  
module.exports = (robot) ->
  karma = new Karma robot
  robot.hear /(\S+[^+\s])\+\+(\s|$)/, (msg) ->
    subject = msg.match[1].toLowerCase()
    karma.increment subject
    msg.send "#{subject} #{karma.incrementResponse()} (Karma: #{karma.get(subject)})"
  
  robot.hear /(\S+[^-\s])--(\s|$)/, (msg) ->
    subject = msg.match[1].toLowerCase()
    karma.decrement subject
    msg.send "#{subject} #{karma.decrementResponse()} (Karma: #{karma.get(subject)})"
  
  robot.respond /karma empty ?(\S+[^-\s])$/i, (msg) ->
    subject = msg.match[1].toLowerCase()
    karma.kill subject
    msg.send "#{subject} has had its karma scattered to the winds."
  
  robot.respond /karma( best)?$/i, (msg) ->
    verbiage = ["The Best"]
    for item, rank in karma.top()
      verbiage.push "#{rank + 1}. #{item.name} - #{item.karma}"
    msg.send verbiage.join("\n")
      
  robot.respond /karma worst$/i, (msg) ->
    verbiage = ["The Worst"]
    for item, rank in karma.bottom()
      verbiage.push "#{rank + 1}. #{item.name} - #{item.karma}"
    msg.send verbiage.join("\n")
  
  robot.respond /karma (\S+[^-\s])$/i, (msg) ->
    match = msg.match[1].toLowerCase()
    if match != "best" && match != "worst"
      msg.send "\"#{match}\" has #{karma.get(match)} karma."
  
  robot.router.get '/hubot/karma', (req, res) ->
    rows = []
    for own key, value of robot.brain.data.karma
      numClass = ""
      if value == 0 then numClass = "zero"
      else if value > 0 then numClass = "positive"
      else numClass = "negative"
      rows.push "<tr><td class=\"key\">#{htmlEscape key}</td><td class=\"value #{numClass}\">#{value}</td></tr>"
    rows.reverse()
    res.writeHead 200,
      "Content-Type": "text/html; charset=utf-8"
    res.write """
      <html>
        <head>
          <title>Instant Karma™</title>
          <style type="text/css">
          html, body{
            font: 16px Courier, monospace;
          }
          table {
            width: 600px;
            max-width: 100%;
            margin: 0 auto;
            border: solid 1px #ecf1ef;
            border-spacing: 5px;
            border-collapse: collapse;
          }
          table tr:nth-child(even) {
            background-color: #ecf1ef;
          }
          table tr:nth-child(odd) {
            background-color: #fff;
          }
          table td {
            padding: 5px;
          }
          table td.key {
            width: 90%;
          }
          table td.value {
            width: 10%;
            text-align: right;
          }
          table td.value.zero {
            color: gray;
          }
          table td.value.negative {
            color: #F18281;
          }
          table td.value.positive {
            color: #3A5FCD;
          }
          </style>
        </head>
        <body>
          <table>
          <tbody>
            #{rows.join '\n      '}
          </tbody>
          </table>
        </body>
      </html>
      """
    res.end()
