class SearchController < ApplicationController
  include SearchHelper

  def index
    @no_results = ""
  end

  def query
    @mech_time = 0
    @yelp_time = 0
    @google_time = 0
    @nokogiri_time = 0

    @mech_detailed_time =  {}
    @google_detailed_time =  {}
    @nokogiri_detailed_time =  {}
    @thread_times = {}

    start = Time.now

    @potential_clients = []
    @location = params[:location]
    @search = params[:business]
    yelp_key = ENV['YELP_API_KEY']

    yelp_start = Time.now
    @yelp_businesses = HTTParty.get("https://api.yelp.com/v3/businesses/search?location=#{@location}&term=#{@search}", headers: {"Authorization" => "Bearer #{yelp_key}"})['businesses']

    @yelp_time = Time.now - yelp_start

    @sugar_bunny = Mechanize.new

    @yelp_business_threads = @yelp_businesses.map{|business| Thread.new{threadTest(business)}}

    @yelp_business_threads.each {|thread| thread.join}

    @no_results = "No potential clients found that match your search request." if @potential_clients.empty?


  p "#{(Time.now - start)} seconds used"

  p "Mechanize Time: #{@mech_time}"
  p "Yelp Time: #{@yelp_time}"
  p "Google Time: #{@google_time}"
  p "Nokogiri Time: #{@nokogiri_time}"

  p "Mechanize Instance Times: "
  p @mech_detailed_time

  p "Google Instance Times: "
  p @google_detailed_time

  p "Nokogiri Instance Times: "
  p @nokogiri_detailed_time

  p "Thread Times:"
  p @thread_times

  render 'search/index'
  end
end
