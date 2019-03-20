require_dependency "dev/application_controller"

require 'zip'
require 'nokogiri'

module Dev
  class MavenController < ApplicationController
    skip_after_action :verify_same_origin_request
    skip_before_action :verify_authenticity_token, :only => [:upload_archive]

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

    EXCLUDED_FILES = %w(.md5 .sha1 .pom)

    def upload_archive
      archive = request.params[:archive]

      Zip::File.open(archive.to_io) do |zf|
        artifacts = zf.select { |e| e.file? && e.name.end_with?(".pom") }.map { |pom_entry|
          pom = Nokogiri::XML(pom_entry.get_input_stream).css("project")

          group = pom.css("groupId").map { |n| n.children.text }.first
          artifact = pom.css("artifactId").map { |n| n.children.text }.first
          version = pom.css("version").map { |n| n.children.text }.first

          files = zf.glob("#{pom_entry.parent_as_string}*").reject { |e| e.name.end_with?(*EXCLUDED_FILES) }

          { entry: pom_entry, files: files, group: group, artifact: artifact, version: version }
        }


      end
      render plain: "Thanks\r\n"
    end
  end
end
