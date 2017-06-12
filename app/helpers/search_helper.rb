module SearchHelper
  def random
    quotes = ["The early bird gets the worm! - Mina", "There is an art to the process of problem solving - Mike Tarkington", "Efficiency Focused - it's always important to work smart in addition to working hard - Mike Tarkington", "Creative Solutions - even the most difficult challenges can be overcome with creativity and cleverness - Mike Tarkington", "You miss all the shots you don't take - Wayne Gretzky - Jesse Calton"]
    return quotes.sample
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
    Timeout::timeout(5) { Nokogiri::HTML(open(long_url))}
  end

  def calculate_seo_points(client_page_dom)
    title_points = has_title?(client_page_dom) ? 15 : 0
    meta_points = meta_score(client_page_dom) > 0 ? 15: 0
    heading_points = heading_count(client_page_dom) > 0 ? 5: 0

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
    return score > 14
  end

  def query_google_api(url)
    Timeout::timeout(12) {HTTParty.get("https://www.googleapis.com/pagespeedonline/v2/runPagespeed?url=#{url}&strategy=mobile&key=#{ENV['SPEED_API_KEY']}")}
  end

  def calculate_page_score(google_response, points_from_seo)
    speed_score = 25 * (google_response["ruleGroups"]["SPEED"]["score"]/100.0)
    usability_score = 45 *(google_response["ruleGroups"]["USABILITY"]["score"]/100.0)

    return speed_score + usability_score + points_from_seo
  end

  def add_potential_client(client)
    @potential_clients << client
  end

  def failed_test(score)
    return score < 79
  end

end
