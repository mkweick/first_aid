class EmailWorker
  include Sidekiq::Worker

  def perform(email, file_path, file_name)
    CustomerCopyMailer.send_email(email, file_path, file_name).deliver_now
  end
end
