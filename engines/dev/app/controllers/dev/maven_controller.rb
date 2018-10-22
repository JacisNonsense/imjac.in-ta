require_dependency "dev/application_controller"

module Dev
  class MavenController < ApplicationController
    skip_after_action :verify_same_origin_request

    def list
      @path = strippath(params[:path] + (params[:format] ? ".#{params[:format]}" : ""))
      @file = Dev::Engine.root.join('app', @path).to_s
      
      if File.exist?(@file)
        if File.directory?(@file)
          @directory = @file
        else
          puts "Sending: #{@file}"
          send_file @file, options: { disposition: 'attachment' }
        end
      else
        not_found
      end
    end

    def strippath path
      path.sub('\\', '/').split('/').reject { |x| x == '..' }.join('/')
    end
  end
end
