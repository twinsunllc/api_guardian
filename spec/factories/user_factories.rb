require 'faker'

password = Faker::Internet.password(32)

FactoryGirl.define do
  factory :user, class: ApiGuardian::User do |f|
    f.first_name { Faker::Name.first_name }
    f.last_name { Faker::Name.last_name }
    f.sequence(:email) { |n| "what#{n}@someplace.com" }
    f.phone_number { Faker::PhoneNumber.phone_number }
    f.password password
    f.password_confirmation password
    f.association :role, factory: :role_with_permissions
    f.association :organization, factory: :organization
  end
end
