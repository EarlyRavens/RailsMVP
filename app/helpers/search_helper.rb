module SearchHelper
  CLIENT_PAGE_TIME_LIMIT = 5
  MAXIMUM_TITLE_SCORE = 15
  MAXIMUM_META_SCORE = 15
  MAXIMUM_HEADING_SCORE = 5
  SEO_MINIMUM_SCORE = 14
  GOOGLE_API_TIME_LIMIT = 12
  MAXIMUM_SPEED_SCORE = 25
  MAXIMUM_USABILITY_SCORE = 45
  MAX_GOOGLE_SCORE = 100.0
  MINIMUM_SUCCESS_BENCHMARK = 79

  def random
    quotes = ["The early bird gets the worm! - Mina", "There is an art to the process of problem solving - Mike Tarkington", "Efficiency Focused - it's always important to work smart in addition to working hard - Mike Tarkington", "Creative Solutions - even the most difficult challenges can be overcome with creativity and cleverness - Mike Tarkington", "You miss all the shots you don't take - Wayne Gretzky - Jesse Calton"]
    return quotes.sample
  end

  def query_yelp_api(form_params)
    HTTParty.get("https://api.yelp.com/v3/businesses/search?location=#{form_params[:location]}&term=#{form_params[:business]}", headers: {"Authorization" => "Bearer #{ENV['YELP_API_KEY']}"})['businesses']
  end
  def threadTest(business)
    business_page_dom = get_page_dom(business)

    if has_a_url?(business_page_dom)
      http_url = client_page(business_page_dom)

      begin
        doc = timeout_scrape_client_page(http_url)

        seo_points = calculate_seo_points(doc)

        if seo_score_filter(seo_points)
          response = query_google_api(http_url)
          page_score = calculate_page_score(response, seo_points)
          add_potential_client(business) if failed_test(page_score)
        else
          add_potential_client(business)
        end

      rescue
        "Business skipped."
      end

    else
      add_potential_client(business)
    end
  end

  private

  def get_page_dom(business)
    @mechanize.get(business['url'])
  end

  def has_a_url?(dom)
    business_url(dom) ? true : false
  end

  def business_url(dom)
    return dom.css('.biz-website a').last
  end

  def client_page(dom)
    return "http://#{business_url(dom).text}"
  end

  def timeout_scrape_client_page(long_url)
    Timeout::timeout(client_page_time_limit) { Nokogiri::HTML(open(long_url))}
  end

  def calculate_seo_points(client_page_dom)
    title_points = has_title?(client_page_dom) ? maximum_title_score : 0
    meta_points = meta_score(client_page_dom) > 0 ? maximum_meta_score : 0
    heading_points = heading_count(client_page_dom) > 0 ? maximum_heading_score : 0

    return title_points + meta_points + heading_points
  end

  def has_title?(dom)
    return !dom.css('title').empty?
  end

  def false_metas_count(dom)
    return dom.css("meta[charset = 'UTF-8']","meta[charset = 'utf-8']","meta[name = 'viewport']").count
  end

  def all_metas_count(dom)
    return dom.css('meta').count
  end

  def meta_score(dom)
    return all_metas_count(dom) - false_metas_count(dom)
  end

  def headings_count(dom)
    return dom.css('h1', 'h2', 'h3').count
  end

  def seo_score_filter(score)
    return score > seo_minimum_score
  end

  def query_google_api(url)
    Timeout::timeout(google_api_time_limit) {HTTParty.get("https://www.googleapis.com/pagespeedonline/v2/runPagespeed?url=#{url}&strategy=mobile&key=#{ENV['SPEED_API_KEY']}")}
  end

  def calculate_page_score(google_response, points_from_seo)
    speed_score = maximum_speed_score * (google_response["ruleGroups"]["SPEED"]["score"]/max_google_score)
    usability_score = maximum_usability_score *(google_response["ruleGroups"]["USABILITY"]["score"]/max_google_score)

    return speed_score + usability_score + points_from_seo
  end

  def add_potential_client(client)
    @potential_clients << client
  end

  def failed_test(score)
    return score < minimum_success_benchmark
  end

end
