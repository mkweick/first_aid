User.create!  first_name: "Dave", last_name: "Smolen", username: "dsmolen",
              password: "smolen", whs_id: "15", active: true

User.create!  first_name: "Eric", last_name: "Krueger", username: "ekrueger",
              password: "krueger", whs_id: '01', admin: true, active: true

User.create!  first_name: "Matt", last_name: "Weick", username: "mweick",
              password: "weick18", whs_id: '01', admin: true, active: true

#25.times do |n|
#  User.create!  first_name: "Test",
#                last_name: "#{n + 1}",
#                username: "test#{n + 1}",
#                password: "test#{n + 1}",
#                whs_id: "#{rand(1..99)}",
#                active: [true, false].sample
#end

puts '-' * 50
puts "Users created: #{User.count}"
puts '-' * 50
