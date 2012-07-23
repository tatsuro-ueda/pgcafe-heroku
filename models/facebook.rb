class Facebook
  include Mongoid::Document
  field :fb_id
  field :object
  field :message
  field :name
  field :description
  field :link
  field :date, :type => Date
end