#!/usr/bin/env ruby

require 'rubygems'
require 'yaml'
require 'twitter'
require 'serialport'
require 'thread'

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
    new_tweets = Twitter::Search.new(@search_terms).since(@last_id)
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

  def initialize(seconds_between_messages = 5, letters_per_second = 5)
    @seconds_between_messages = seconds_between_messages
    @letters_per_second = letters_per_second
    @serial = SerialPort.new 0, 19200
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

puts "First run, must configurate..."
puts "Search terms: "
TERMS = gets.chop
CONFIG = {'Configuration' => {
  'Search Terms' => TERMS,
  'Tweet Count' => 10
  }}


twitter_client = TwitterClient.new(TERMS,5)
vfd = Vfd.new(5,8)

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