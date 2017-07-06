require 'machinist/active_record'
require 'sham'
require 'faker'

def rand_in_range(from, to)
  rand * (to - from) + from
end

def rand_time(from, to)
  Time.at(rand_in_range(from.to_f, to.to_f))
end

Sham.define do
  name { Faker::Name.name }
  email { Faker::Internet.email }
  phone_number { rand(1111111..9999999) }
  password { Faker::Name.name }
  username { Faker::Internet.user_name }
  color { "##{rand(255**3).to_s(16)}" }
  icon { Faker::Name.name }
  sn { |i| i }
end

User.blueprint do
  email
  password
  phone_number
  confirmed_at { Time.now }
end

Collection.blueprint do
  name
  icon {'default'}
end

Site.blueprint do
  collection
  name
  lat { rand(180) - 90 }
  lng { rand(360) - 180 }
  user { User.make }
end

Layer.blueprint do
  collection
  name
  ord { collection.next_layer_ord }
  user { User.make }
end

Field.subclasses.each do |field_kind|
  field_kind.name.constantize.blueprint do
    layer
    collection { layer.collection }
    name
    code { Sham.name }
    ord { layer.next_field_ord }
  end
end

Activity.blueprint do
end

SiteHistory.blueprint do
  collection
  name
  lat { rand(180) - 90 }
  lng { rand(360) - 180 }
  valid_since {rand_time(2.days.ago, Time.now)}
  valid_to nil
end

Threshold.blueprint do
  collection
  ord { Sham.sn }
  color { Sham.color }
end

Snapshot.blueprint do
  collection
  date {rand_time(2.days.ago, Time.now)}
  name { Sham.username }
end

UserSnapshot.blueprint do
  snapshot
  user
end

Repeat.blueprint do
  rule { IceCube::Rule.weekly }
end

Reminder.blueprint do
  repeat
end

Channel.blueprint do
  user
end

Membership.blueprint do
  user
  collection
  admin { false }
end

ImportJob.blueprint do
  user
  collection
  status
end

ReportQuery.blueprint do
  name { Faker::Name.name }
end

ReportQueryTemplate.blueprint do
  name { Faker::Name.name }
  template {Faker::Name.name}
  report_query
end
