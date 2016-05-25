require 'native'
class OpalHotReloader
  class CssReloader

    def reload(reload_request, document)
      url = reload_request[:url]
      puts "Reloading CSS: #{url}"
      to_append = "t_hot_reload=#{Time.now.to_i}"
      links = Native(`document.getElementsByTagName("link")`)
      (0..links.length-1).each { |i|
        link = links[i]
        if link.rel == 'stylesheet' && link.href.index(url) # # find_matching_stylesheets(link.href, url)
          if  link.href !~ /\?/
            link.href += "?#{to_append}"
          else
            if link.href !~ /t_hot_reload/
              link.href += "&#{to_append}"
            else
              link.href = link.href.sub(/t_hot_reload=\d{13}/, to_append)
            end
          end
        end
      }
    end
    

  end
end
