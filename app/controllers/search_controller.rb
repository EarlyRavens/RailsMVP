class SearchController < ApplicationController
  include SearchHelper

  def index
    @no_results = ""
  end

  def query
    @potential_clients = []

    @yelp_businesses = HTTParty.get("https://api.yelp.com/v3/businesses/search?location=#{params[:location]}&term=#{params[:business]}", headers: {"Authorization" => "Bearer #{ENV['YELP_API_KEY']}"})['businesses']

    @mechanize = Mechanize.new

    @yelp_business_threads = @yelp_businesses.map{|business| Thread.new{threadTest(business)}}
    @yelp_business_threads.each {|thread| thread.join}

    @no_results = "No potential clients found that match your search request." if @potential_clients.empty?

    render 'search/index'
  end
end
