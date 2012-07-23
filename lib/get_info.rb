require 'sinatra'
require 'addressable/uri'
require 'open-uri'
require 'json'

include Addressable

class GetEventFromATND
  URL     = "http://api.atnd.org/events/?format=json&keyword="
  KEYWORD = "%e3%83%97%e3%83%ad%e3%82%b0%e3%83%a9%e3%83%9e%e3%83%bc%e3%82%ba%e3%82%ab%e3%83%95%e3%82%a7"
  
  def initialize
    Event.destroy_all
    uri = URI.parse(URL+KEYWORD)
    json = open(uri).read
    ref = JSON.parse(json)
    ref['events'].each do |event|
      if Time.parse(event['ended_at']) >= Time.now
        Event.create(category: 'atnd', name: event['title'], description: event['description'], url: event['event_url'], 
                  dtstart: Time.parse(event['started_at']), dtend: Time.parse(event['ended_at']))
      end
    end
    if Event.where(category: 'atnd').length == 0
      day = Time.now
      if day.wday <= 4
        w = 4 - day.wday
      elsif day.wday > 4
        w = 7 - (day.wday - 4)
      end
      Event.create(category: 'atnd', url: '', dtstart: Time.parse(day + w), dtend: Time.parse(day + w))
    end
  end
end

class GetEventFromGoogleCalendar
  URL = "https://www.google.com/calendar/ical/mroq255j953tfk6jsu2gf77trk%40group.calendar.google.com/public/basic.ics"
  
  def initialize
    Event.destroy_all
    uri = URI.parse(URL)
    ical = open(uri).read
    cal = Icalendar.parse(ical, true)
    cal.events.each do |event|
      r = ''
      event.recurrence_rules.map do |rule|
        # rule.orig_value.scan(/(\w+)\=([\w,]+)/)
        r << rule.orig_value.to_s
      end
      Event.create(category: 'google', name: event.summary, description: event.description, rrule: r, 
                dtstart: Time.parse(event.dtstart.to_s), dtend: Time.parse(event.dtend.to_s))
    end
  end
end

  
class GetInfoFromFacebook
  FB_APP_ID = '325394417554551'
  FB_SECRET = 'bc6138c5964b18f837f55bab9536e918'
  URL = "https://graph.facebook.com/oauth/access_token?client_id=#{FB_APP_ID}&client_secret=#{FB_SECRET}&grant_type=client_credentials"
  
  def initialize
    Facebook.destroy_all
    uri = URI.parse(URL)
    open(uri).read.match(/=/)
    url = URI.escape("https://graph.facebook.com/331378793553152/links?access_token=#{$'}")
    uri = URI.parse(url)
    json = open(uri).read
    ref = JSON.parse(json)
    ref['data'].each do |fb|
      obj = 'link'
      obj = 'event' if /event/ =~ fb['link'].to_s
      obj = 'other' if fb['id'] == "235954356515818" or fb['id'] == "424671060897706"
      Facebook.create(fb_id: fb['id'], object: obj, 
                message: fb['message'].to_s.gsub(/(http[\S]+)/, '').sub(/^\n/, '').sub(/[\n|\S]\z/m, ''), 
                name: fb['name'], 
                description: fb['description'].to_s.gsub(/(http[\S]+)/, '').sub(/^\n/, '').sub(/[\n|\S]\z/m, ''), 
                link: fb['link'], date: Time.parse(fb['created_time']))
    end
  end
end
