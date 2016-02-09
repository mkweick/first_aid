class CustomerCopyMailer < ApplicationMailer

  def send_email(email, file_path, file_name)
    attachments[file_name] = File.read(file_path)
    mail(to: email, subject: "First Aid Service - DiVal Safety")
  end
end
