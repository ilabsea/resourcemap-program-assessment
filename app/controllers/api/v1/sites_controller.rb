module Api::V1
  class SitesController < ApplicationController
    include Concerns::CheckApiDocs
    include Api::JsonHelper

    before_filter :authenticate_api_user!
    skip_before_filter  :verify_authenticity_token
    expose(:site) { Site.find(params[:site_id] || params[:id]) }

    def index
      search = new_search

      search.my_site_search current_user.id unless current_user.can_view_other? params[:collection_id]
      search.offset params[:offset]
      search.limit params[:limit]

      sites_size = search.results.total

      render :json =>{:sites => search.ui_results.map { |x| x['_source'] }, :total => sites_size}
    end

    def show
      search = new_search

      search.id(site.id)
      @result = search.api_results[0]

      respond_to do |format|
        format.rss
        format.json { render json: site_item_json(@result) }
      end
    end

    def update
      site.attributes = sanitized_site_params(false).merge(user: current_user)

      if site.valid?
        site.save!
        if params[:photosToRemove]
          Site::UploadUtils.purgePhotos(params[:photosToRemove])
        end
        render json: site, :layout => false
      else
        render json: site.errors.messages, status: :unprocessable_entity, :layout => false
      end
    end

    def create
      site = build_site
      create_state = site.id ? false : true #to create or update
      site.user_id = current_user.id
      if site.save
        if create_state
          current_user.site_count += 1
          current_user.update_successful_outcome_status
          current_user.save!(:validate => false)
        end
        render json: site, status: :created
      else
        render json: site.errors.messages, status: :unprocessable_entity
      end
    end

    private
    def sanitized_site_params new_record
      parameters = params[:site]

      result = new_record ? {} : site.filter_site_by_id(params[:id])

      fields = collection.fields.index_by &:es_code
      site_properties = parameters.delete("properties") || {}

      files = parameters.delete("files") || {}
      
      decoded_properties = new_record ? {} : result.properties
      site_properties.each_pair do |es_code, value|
        value = [ value, files[value] ] if fields[es_code].kind_of? Field::PhotoField
        decoded_properties[es_code] = fields[es_code].decode_from_ui(value) if fields[es_code]
      end

      parameters["properties"] = decoded_properties
      parameters
    end

    def build_site
      site = collection.is_site_exist? params[:site][:device_id], params[:site][:external_id] if params[:site][:device_id]
      if site
        params[:id] = site.id
        site.attributes = sanitized_site_params(false).merge(user: current_user)
      else
        site = collection.sites.build sanitized_site_params(true).merge(user: current_user)
      end
      return site
    end

  end
end