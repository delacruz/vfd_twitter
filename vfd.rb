#!/usr/bin/env ruby

require 'rubygems'
require 'yaml'
require 'twitter'
require 'serialport'
require 'thread'
require 'twitter_oauth'

class TwitterClient
  
  def initialize(search_terms, tweets_to_remember = 5)
    @search_terms = search_terms
    @tweets_to_remember = tweets_to_remember
    @tweets = Array.new
    @last_id = 1
  end
  
  # Add a tweet
  def add(tweet)
    if @tweets.push(tweet).length > @tweets_to_remember
      @tweets.shift
    end
  end
  
  def pull_new_tweets
    puts "Pulling new tweets since #{@last_id}..."
    new_tweets = Twitter::Search.new.containing(@search_terms).since_id(@last_id)
    new_tweets.each do |tweet| 
      add(tweet.text) 
      if tweet.id > @last_id then
        @last_id = tweet.id
      end
    end
    @tweets
  end
  
end

class Vfd

  Nothing = 0x00
  MoveCursorLeft = 0x08 #backspace
  MoveCursorRight = 0x09 #tab
  MoveCursorDown = 0x0A #linefeed
  MoveCursorToTopLeft = 0x0C #formfeed
  MoveCursorToLineStart = 0xD #carriage return
  ClearScreen = 0x0E
  DisableScroll = 0x11
  EnableScroll = 0x12
  CursorOff = 0x14
  CursorOn = 0x15
  CursorOff2 = 0x16
  CursorOff3 = 0x17
  OtherCharacterSet = 0x19
  NormalCharacterSet = 0x1A

  def initialize(serial_port, seconds_between_messages = 5, letters_per_second = 5)
    @seconds_between_messages = seconds_between_messages
    @letters_per_second = letters_per_second
    @serial = SerialPort.new "#{serial_port}", 19200
  end
  
  def show_messages(messages)
    messages.each do |message|
      @serial.write EnableScroll.chr
      @serial.write MoveCursorToTopLeft.chr
      @serial.write ClearScreen.chr
      message.each_char do |c| 
        print c
        @serial.write c
        STDOUT.flush
        sleep(1.0/@letters_per_second)
      end
      sleep @seconds_between_messages
      puts
    end
  end

  def close
    @serial.close
  end
  
end

# Twitter Consumer Key/Secret
CONSUMER_KEY = "s8tJJJ3gQ853mpqfbDvug"
CONSUMER_SECRET = "R5goF5PuXOnhOguHRqtCk1fGVixqnfsfCS4np5QZeE"

puts "First run, must configure..."
puts "Select a search mode: "
puts "1. Search Terms\n2. User Tweets\n3. Your Twitter Account Feed\n"
puts "Search Mode (1-3):"
MODE = gets.chop
case MODE
when "1"
  puts "Enter search terms: "
  TERMS = gets.chop
when "2"
  puts "Enter username: "
  SEARCHUSER = gets.chop
when "3"
  client = TwitterOAuth::Client.new(
    :consumer_key => CONSUMER_KEY, 
    :consumer_secret => CONSUMER_SECRET
  )
  
  request_token = client.request_token()
  
  %x(open #{request_token.authorize_url})
  
  puts "Pin: "
  pin = gets.chop
  
  access_token = client.authorize(
    request_token.token,
    request_token.secret,
    :oauth_verifier => pin
  )
  
  puts client.authorized?
  
 
  #puts "If web browser wasn't automatically launched, use this URL to get your pin #{oauth.request_token.authorize_url}"
  #puts "Enter pin"
  #pin = gets.chop
  #oauth.authorize_from_request(oauth.request_token.token, oauth.request_token.secret, pin)
  #output = File.new('config.yml', 'w')
  #output.puts YAML.dump(oauth.access_token.token,oauth.access_token.secret)
end
puts "Serial port (ie. /dev/ttyS0 or COM1): "
SERIALPORT = gets.chop
CONFIG = {'Configuration' => {
  'Serial Port' => SERIALPORT,
  'Tweet Count' => 10,
  'Search Terms' => TERMS
}}
  
  


twitter_client = TwitterClient.new(TERMS,5)
vfd = Vfd.new(SERIALPORT,5,8)

tweet_poll_thread = Thread.new do
  loop { vfd.show_messages twitter_client.pull_new_tweets }
end

puts "Press return to exit..."
gets

vfd.close

tweet_poll_thread.exit
puts "waiting for thread to join"
tweet_poll_thread.join
puts "thread joined"