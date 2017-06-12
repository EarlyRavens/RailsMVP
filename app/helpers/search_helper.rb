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

          if seo_points > 10
          # If the business gotten at least 10 seo points the business automatically has a shitty website since you need at least 79 points to pass test

            response = Timeout::timeout(12) { HTTParty.get("https://www.googleapis.com/pagespeedonline/v2/runPagespeed?url=#{http_url}&strategy=mobile&key=#{speed_key}") }

            page_score = (25 *(response["ruleGroups"]["SPEED"]["score"]/100.0)) + (45 *(response["ruleGroups"]["USABILITY"]["score"]/100.0)) + seo_points

            @potential_clients << business if page_score < 79
          else
            @potential_clients << business
          end
          rescue
            #add something here if we want
          end
      else
        @potential_clients << business
      end
  end
end
