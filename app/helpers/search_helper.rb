module SearchHelper
  def random
    quotes = ["The early bird gets the worm! - Mina", "There is an art to the process of problem solving - Mike Tarkington", "Efficiency Focused - it's always important to work smart in addition to working hard - Mike Tarkington", "Creative Solutions - even the most difficult challenges can be overcome with creativity and cleverness - Mike Tarkington", "You miss all the shots you don't take - Wayne Gretzky - Jesse Calton"]
    return quotes.sample
  end

  def threadTest(business)
      yelp_url = business['url']
      business_page = @mechanize.get(yelp_url)

      if business_page.css('.biz-website a').last
        client_page = business_page.css('.biz-website a').last.text
        http_url = 'http://' + client_page
        speed_key = ENV['SPEED_API_KEY']
        begin
          doc = Timeout::timeout(5) { Nokogiri::HTML(open(http_url)) }
          # if URL redirects to https -> Nokogiri skips to rescue

          has_title = doc.css('title').length > 0
          title_points = has_title ? 15 : 0
          # The business gets 15 points if it has a title

          false_meta1 = doc.css("meta[charset = 'UTF-8']") ? 1 : 0
          false_meta2 = doc.css("meta[name = 'viewport']") ? 1 : 0
          meta_count = doc.css('meta').count - (false_meta1 + false_meta2)
          meta_points = meta_count > 0 ? 15: 0
          # The business gets 15 points if it has metatag, we removed any meta tags that are standard (charset = 'UTF-8', name = 'viewport')

          heading_count = doc.css('h1', 'h2', 'h3').count
          heading_points = heading_count > 0 ? 5: 0
          # If the business site has any headings, it gets 5 points

          seo_points = title_points + meta_points + heading_points

          if seo_score_filter(seo_points)
          # If the business gotten at least 10 seo points the business automatically has a shitty website since you need at least 79 points to pass test

            response = query_google_api(http_url)
            page_score = calculate_page_score(response,seo_points)
            add_potential_client(business) if failed_test(page_score)

          else

            add_potential_client(business)

          end
          rescue
            p "Business skipped."
          end
      else
        add_potential_client(business)
      end
  end

  private

  def add_potential_client(client)
    @potential_clients << client
  end

  def calculate_page_score(google_response, points_from_seo)
    speed_score = 25 * (google_response["ruleGroups"]["SPEED"]["score"]/100.0)
    usability_score = 45 *(google_response["ruleGroups"]["USABILITY"]["score"]/100.0)

    return speed_score + usability_score + points_from_seo
  end

  def failed_test(score)
    return score < 79
  end

  def query_google_api(url)
    Timeout::timeout(12) { HTTParty.get("https://www.googleapis.com/pagespeedonline/v2/runPagespeed?url=#{url}&strategy=mobile&key=#{ENV['SPEED_API_KEY']}")}
  end

  def seo_score_filter(score)
    return score > 14
  end
end
