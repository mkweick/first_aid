class CustomerCopyMailer < ApplicationMailer

  def test_email(email)
    mail(to: email, subject: 'Test Email!!!!')
  end
end
