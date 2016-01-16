#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

User.create!  first_name: "Dave", last_name: "Smolen", username: "dsmolen",
              password: "smolen", whs_id: "15"

puts '-' * 50
puts "Users created: #{User.count}"
puts '-' * 50
