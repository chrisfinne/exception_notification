require 'pathname'

# Copyright (c) 2005 Jamis Buck
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
class ExceptionNotifier < ActionMailer::Base
  @@sender_address = %("Exception Notifier" <exception.notifier@default.com>)
  cattr_accessor :sender_address

  @@exception_recipients = []
  cattr_accessor :exception_recipients

  @@email_prefix = "[ERROR] "
  cattr_accessor :email_prefix

  @@sections = %w(request session environment backtrace)
  cattr_accessor :sections

  self.template_root = "#{File.dirname(__FILE__)}/../views"

  def self.reloadable?() false end

  def exception_notification(exception, controller, request, data={})
    content_type "text/plain"

    subject    "#{email_prefix}#{controller.controller_name}##{controller.action_name} (#{exception.class}) #{exception.message.inspect}"

    recipients exception_recipients
    from       sender_address

    body       data.merge({ :controller => controller, :request => request,
                  :exception => exception, :host => (request.env["HTTP_X_FORWARDED_HOST"] || request.env["HTTP_HOST"]),
                  :backtrace => sanitize_backtrace(exception.backtrace),
                  :rails_root => rails_root, :data => data,
                  :sections => sections })
  end

  def exception_email(exception, notes=nil, request=nil)
    if exception.is_a?(Exception)
      logger.error exception.backtrace
      subject    "#{email_prefix} (#{exception.class}) #{exception.message.inspect}"
      body[:backtrace] = sanitize_backtrace(exception.backtrace)
    elsif exception.is_a?(String)
      logger.error "EXCEPTION: #{exception}"
      subject    "#{email_prefix} #{exception}"
    else
      logger.error "(#{exception.class})"
      subject    "#{email_prefix} (#{exception.class})"
    end
    
    recipients exception_recipients
    from       sender_address

    body[:exception]=exception
    body[:notes]=notes.to_s
    body[:request]=request
  end
  
  def admin_email(the_subject,the_body)
    from       CP_SYSTEM_EMAIL
    recipients CP_ADMIN_EMAIL
    subject    the_subject
    body[:body]=the_body
  end

  private

    def sanitize_backtrace(trace)
      re = Regexp.new(/^#{Regexp.escape(rails_root)}/)
      trace.map { |line| Pathname.new(line.gsub(re, "[RAILS_ROOT]")).cleanpath.to_s }
    end

    def rails_root
      @rails_root ||= Pathname.new(RAILS_ROOT).cleanpath.to_s
    end

end
