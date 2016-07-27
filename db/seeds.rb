User.create!  first_name: "IT", last_name: "Admin", username: "admin",
              password: "Tdot1721#", whs_id: '15', admin: true, active: true

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
