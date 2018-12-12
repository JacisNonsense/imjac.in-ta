class SubdomainController < ActionController::Base

  def redirect
    redirect_to "#{request.protocol}#{request.domain}:#{request.port}/#{request.subdomain}#{request.path}"
  end

end
