class Event
  include Mongoid::Document
  field :category
  field :name
  field :description
  field :rrule
  
  field :dtstart, :type => Date
  field :dtend, :type => Date
  field :url
end