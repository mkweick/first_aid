class ApplicationMailer < ActionMailer::Base
  default from: "\"First Aid Service - No Reply\" <noreply_FirstAid@divalsafety.com>"
  layout 'mailer'
end
