require_dependency "dev/application_controller"

require 'zip'
require 'nokogiri'
require 'digest'

module Dev
  class MavenController < ApplicationController
    skip_after_action :verify_same_origin_request
    # For CSRF
    skip_before_action :verify_authenticity_token, :only => [:upload_archive]

    include MavenHelper

    # Main entrypoint for `maven/*`
    def list
      path_str = params[:path]

      is_sha1 = params[:format] == "sha1"
      is_md5 = params[:format] == "md5"
      is_hash = is_sha1 || is_md5

      path_str += "." + params[:format] unless (is_hash || params[:format].nil?)
      path_components = strippath(path_str).split('/')

      if path_components.last == "maven-metadata.xml"
        # Maven Metadata is stored in ActiveRecord, not in a file asset, so it's a bit special.
        parent = path_components[0..-2].join('/')
        artifact = MavenArtifact.where(path: parent).take
        if artifact
          unless is_hash
            render xml: artifact.metadata
          else
            render plain: is_sha1 ? artifact.metadata_sha1 : artifact.metadata_md5
          end
        else
          not_found
        end
      else
        # Regular file asset (or path)
        path = path_components.join('/')
        file = MavenFile.where(path: path).take

        if file
          # File found
          if is_hash
            render plain: is_sha1 ? file.sha1 : file.md5
          else
            file.download_count += 1
            file.save
            redirect_to main_app.rails_blob_path(file.file, disposition: "attachment", only_path: true)
          end
        else 
          # Incomplete, either a MavenVersion or MavenArtifact. Hash can be ignored.
          @dirs = []
          @files = []
          @path = path 
          @here = request.url

          version = MavenVersion.where(path: path).take
          if version
            # Collect the files and present them for rendering
            @files = version.maven_files.map { |x| { name: x.name, sha1: x.sha1, md5: x.md5, size: x.file.blob.byte_size } }
          else
            artifact = MavenArtifact.where(path: path).take
            if artifact
              # In an artifact - collect the versions and present them (+ the metadata file)
              @dirs = artifact.maven_versions.map { |x| { name: x.version, childs: x.maven_files.count, child_tags: "Files" } }
              @files = [ { name: 'maven-metadata.xml', sha1: artifact.metadata_sha1, md5: artifact.metadata_md5, size: artifact.metadata.size } ]
            else
              # Path is partial. Collect the artifacts and get the ones the next-level-down
              artifacts = MavenArtifact.where("path LIKE :p", p: "#{path}%")
              not_found if artifacts.empty?
              subdirs = {}             
              artifacts.each do |art|
                # Reject parts of the path in common
                submembers = art.path.split('/').select.each_with_index do |path_el, i| 
                  path_components[i] != path_el
                end
                member = submembers.first  # Get only the next entry, e.g. ["pathfinder", "Pathfinder-Core"] will return "pathfinder"

                # Make the entries unique, with a count of how many elements are inside
                subdirs[member] ||= { name: member, childs: 0, child_tags: "Artifacts" }
                subdirs[member][:childs] += 1
              end
              @dirs = subdirs.values
            end
          end
        end
      end
    end

    def strippath path
      path.sub('\\', '/').split('/').reject { |x| x == '..' }.join('/')
    end

    EXCLUDED_FILES = %w(.md5 .sha1)

    def token_check
      user = deploy_token_owner(request.params[:token])
      unless user.nil?
        render plain: user.username
      else
        render plain: "Invalid token", status: :unauthorized
      end
    end

    # Entrypoint for `maven/admin/upload/archive` (POST)
    # TODO: This should be a job
    def upload_archive
      (render plain: "Unauthorized!", status: :unauthorized and return) if deploy_token_owner(request.params[:token]).nil?

      archive = request.params[:archive]

      Zip::File.open(archive.to_io) do |zf|
        zf.select { |e| e.file? && e.name.end_with?(".pom") }.each do |pom_entry|
          pom = Nokogiri::XML(pom_entry.get_input_stream).css("project")

          # Get GroupID, ArtifactID and Version from the POM. It's easier than scanning
          # the path, and more resistant to silly zip packaging.
          groupId = pom.css("groupId").map { |n| n.children.text }.first
          artifactId = pom.css("artifactId").map { |n| n.children.text }.first
          version = pom.css("version").map { |n| n.children.text }.first

          # Ensure that we're getting the files we want. That means no poms or hashes,
          # but does mean any file that follows the ArtifactId-VERS-classifier.ext naming 
          # convention.
          files = zf.glob("#{pom_entry.parent_as_string}*").select do |e| 
            !e.name.end_with?(*EXCLUDED_FILES) && File.basename(e.name).start_with?("#{artifactId}-#{version}")
          end

          logger.info "Maven Artifact Upload Init: #{groupId}:#{artifactId}:#{version} (#{files.size} file(s))"

          # Create the artifact if it doesn't already exist
          artifact_path = "#{groupId.gsub('.', '/')}/#{artifactId}"
          artifact_record = MavenArtifact.find_or_create_by(group: groupId, artifact: artifactId, path: artifact_path)

          # Create the maven version and attach the POM
          version_path = "#{artifact_path}/#{version}"
          version_record = artifact_record.maven_versions.find_or_create_by(version: version, path: version_path)

          # Attach maven files
          MavenFile.transaction do
            files.each do |file_entry|
              zip_tmp_extract(file_entry) do |file|
                filename = File.basename(file_entry.name)
                logger.info "Processing file #{filename}...."

                md5 = Digest::MD5.file(file).hexdigest
                sha1 = Digest::SHA1.file(file).hexdigest
                logger.info " -> MD5: #{md5} SHA1: #{sha1}"

                file_path = "#{version_path}/#{filename}"
                file_record = version_record.maven_files.find_or_create_by(path: file_path, name: filename)

                file_record.file.purge unless file_record.file.nil?
                file_record.file.attach(io: File.open(file), filename: filename)
                file_record.md5 = md5
                file_record.sha1 = sha1
                file_record.save

                if artifactId.ends_with?("FRCDeps") && filename.ends_with?(".json")
                  logger.info "Found FRCDeps File: #{filename}"
                  upload_frcdeps_file(file)
                end
              end
            end
          end

          # Format & update metadata
          all_versions = artifact_record.maven_versions.order(updated_at: :asc).map(&:version)
          metadata_string = [
            "<?xml version=\"1.0\" encoding=\"UTF-8\"?>",
            "<metadata>",
            "  <groupId>#{groupId}</groupId>",
            "  <artifactId>#{artifactId}</artifactId>",
            "  <versioning>",
            "    <release>#{all_versions.last}</release>",
            "    <versions>",
            all_versions.map { |v| "      <version>#{v}</version>" },
            "    </versions>",
            "    <lastUpdated>#{Time.new.getutc.strftime("%Y%m%d%H%M%S")}</lastUpdated>",
            "  </versioning>",
            "</metadata>"
          ].flatten.join("\n")

          artifact_record.metadata = metadata_string
          artifact_record.metadata_md5 = Digest::MD5.hexdigest(metadata_string)
          artifact_record.metadata_sha1 = Digest::SHA1.hexdigest(metadata_string)
          artifact_record.save
          
          logger.info "DONE!"
        end
      end

      render plain: "done!\r\n"
    end

    # TODO: Manage tokens properly the rails way
    def token_manager
      authenticate_admin!

      @new_token = DeployToken.new(user: current_user, token: SecureRandom.uuid)
      @tokens = DeployToken.all
    end

    def create_token
      authenticate_admin!

      DeployToken.create(user: current_user, token: params[:deploy_token][:token], description: params[:deploy_token][:description])
      redirect_to request.referer
    end

    def revoke_token
      authenticate_admin!

      DeployToken.where(token: params[:id]).destroy_all
      redirect_to request.referer
    end

    def frclist
      @deps = MavenFrcdep.all
      @here = request.url
    end

    def frcdep
      uuid = params[:uuid]
      view_only = params.include? :view

      dep = MavenFrcdep.where(uuid: uuid).take
      not_found unless dep

      if view_only
        render json: dep.json
      else
        send_data dep.json, filename: dep.filename
      end
    end
  end
end
