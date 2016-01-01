class CustomerCopyMailer < ApplicationMailer

  def send_email(email, filename, pdf_path)
    attachments["#{ filename }.pdf"] = File.read(pdf_path)
    mail( to: email, subject: "DiVal Safety - First Aid Service")
  end
end
