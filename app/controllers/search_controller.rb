class SearchController < ApplicationController
  include SearchHelper

  def index
    @no_results = ""
  end

  def query
    @potential_clients = []

    @yelp_businesses = query_yelp_api(params)

    @mechanize = Mechanize.new

    @yelp_business_threads = @yelp_businesses.map{|business| Thread.new{threadTest(business)}}
    @yelp_business_threads.each {|thread| thread.join}

    @no_results = "No potential clients found that match your search request." if @potential_clients.empty?

    render 'search/index'
  end
end
