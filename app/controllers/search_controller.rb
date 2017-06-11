class SearchController < ApplicationController
  include SearchHelper

  def index
    @no_results = ""
  end

  def query
    start = Time.now
    @potential_clients = []
    @location = params[:location]
    @search = params[:business]
    yelp_key = ENV['YELP_API_KEY']


    @yelp_businesses = HTTParty.get("https://api.yelp.com/v3/businesses/search?location=#{@location}&term=#{@search}", headers: {"Authorization" => "Bearer #{yelp_key}"})['businesses'][0..10]


    @sugar_bunny = Mechanize.new

    @yelp_business_threads = @yelp_businesses.map{|business| Thread.new{threadTest(business)}}

    @yelp_business_threads.each do |thread|
      thread.join
    end

    # @yelp_businesses.each do |business|

      # yelp_url = business['url']

      # business_page = @sugar_bunny.get(yelp_url)

      # if business_page.css('.biz-website a').last
      #   client_page = business_page.css('.biz-website a').last.text
      #   http_url = 'http://' + client_page
      #   speed_key = ENV['SPEED_API_KEY']
      #   begin
      #     # noko_start = Time.now
      #     doc = Nokogiri::HTML(open(http_url))

      #     has_title = doc.css('title').length > 0
      #     title_points = has_title ? 15 : 0
      #     # The business gets 15 points if it has a title

      #     false_meta1 = doc.css("meta[charset = 'UTF-8']") ? 1 : 0
      #     false_meta2 = doc.css("meta[name = 'viewport']") ? 1 : 0
      #     meta_count = doc.css('meta').count - (false_meta1 + false_meta2)
      #     meta_points = meta_count > 0 ? 15: 0
      #     # The business gets 15 points if it has metatag, we removed any meta tags that are standard (charset = 'UTF-8', name = 'viewport')

      #     heading_count = doc.css('h1', 'h2', 'h3').count
      #     heading_points = heading_count > 0 ? 5: 0

      #     # If the business site has any headings, it gets 5 points

      #     seo_points = title_points + meta_points + heading_points

      #     if seo_points > 10
      #       response = HTTParty.get("https://www.googleapis.com/pagespeedonline/v2/runPagespeed?url=#{http_url}&strategy=mobile&key=#{speed_key}")

      #       page_score = (25 *(response["ruleGroups"]["SPEED"]["score"]/100.0)) + (45 *(response["ruleGroups"]["USABILITY"]["score"]/100.0)) + seo_points

      #       @potential_clients << business if page_score < 79
      #     else
      #       @potential_clients << business
      #     end
      #     rescue
      #       #add something here if we want
      #     end
      # else
      #   @potential_clients << business
      # end
    # end

  if @potential_clients.empty?
    @no_results = "No potential clients found that match your search request."
  end

  p "#{(Time.now - start)} seconds used"

  render 'search/index'
  end
end
