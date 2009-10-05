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

  def initialize(seconds_between_messages = 5, letters_per_second = 5)
    @seconds_between_messages = seconds_between_messages
    @letters_per_second = letters_per_second
  end
  
  def show_messages(messages)
    messages.each do |message|
      message.each_char { |c| print c; STDOUT.flush; sleep(1.0/@letters_per_second) }
      sleep @seconds_between_messages
      puts
    end
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
vfd = Vfd.new(5,30)

tweet_poll_thread = Thread.new do
  vfd.show_messages twitter_client.pull_new_tweets
end

puts "Press return to exit..."
gets
tweet_poll_thread.exit
puts "waiting for thread to join"
tweet_poll_thread.join
puts "thread joined"
 

