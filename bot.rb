# use karl's chat-adapter library
require 'chat-adapter'
# also use the local HerokuSlackbot class defined in heroku.rb
require './heroku'
require 'pry'

# if we're on our local machine, we want to test our bot via shell, but when on
# heroku, deploy the actual slackbot.
# 
# Feel free to change the name of the bot here - this controls what name the bot
# uses when responding.
if ARGV.first == 'heroku'
  bot = HerokuSlackAdapter.new(nick: 'preorderbot')
else
  bot = ChatAdapter::Shell.new(nick: 'preorderbot')
end

# Feel free to ignore this - makes logging easier
log = ChatAdapter.log

Metric = Struct.new(:name, :weight, :help_message, :value)
listening = false
metrics = []
#metrics iterator
i = 0

def greeting_prompt()
  "\e[H\e[2J\nType h for help on any metric, q to quit, b to go back, and s to start over.
  Enter your evaluation, on an integer scale of 1 to 10"
end

def error_prompt()
  "Enter your evaluation, on an integer scale of 1 to 10,
  or \"h\" for help | \"b\" for back | \"s\" to start over | \"q\" to quit"
end

# Do this thing in this block each time the bot hears a message:
bot.on_message do |message, info|
  # ignore all messages not directed to this bot
  unless (message.start_with?('hello, preorderbot') || listening)
    next # don't process the next lines in this block
  end

  response = ""

  #initiate new preorder plot
  if (message.start_with?('hello, preorderbot') && !listening)
    listening = true

    # Set up preorder metrics:
    metrics = [

      Metric.new("complexity",0.10,"How difficult will it be to meet customer expectations? (10 is most difficult)"),
      Metric.new("scale",0.14,"How far is the realistic expected reach? (10 is largest scale)"),
      Metric.new("imprecision",0.12,"How aligned are the expectations of the merchant with realistic complexity/scale? (10 is least precise/aligned)"),
      Metric.new("inexperience",0.10,"How experienced is the merchant in producing something like this preorder? (10 is least experienced)"),
      Metric.new("manufacturing",0.16,"How difficult to meet are the manufacturing plans? (10 is hardest, least firm/predictable)"),
      Metric.new("lead_time",0.18,"How far ahead are customers preordering? (10 is a year or more ahead)"),
      Metric.new("dependency",0.20,"How dependent is the merchant on direct preorder funds? (10 is 100% dependent)")

    ]

    response += greeting_prompt()
    response += "\n\n#{metrics[i].name}"

  elsif (listening && i != metrics.size)

    if message.downcase == "h"
      response += metrics[i].help_message
    elsif message.downcase == "q"
      listening = false
      i = 0
      next
    elsif message.downcase == "b"
      unless i == 0 then i = i - 1 end
    elsif message.downcase == "s"
      i = 0
    elsif message.to_i >= 1 && message.to_i <= 10
      metrics[i].value = message.to_i
      i = i + 1
    else
      response += error_prompt
    end

    if (i != metrics.size)
      response += "\n\n#{metrics[i].name}"
    else
      response = "What's the expected preorder volume?"
    end

  else

    preorder_volume = message.to_f
    listening = false
    i = 0
    score = 0.0
    metrics.each do |m| 
      score = score + (m.value * m.weight)
    end
    response = "\n========\nRecommended reserve from $#{preorder_volume.round(2)}: #{(score * 10).round(1)}\%\n\n"
  end

  response

end

# actually start the bot
bot.start!