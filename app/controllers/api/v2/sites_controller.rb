module Api::V2
  class SitesController < ApiController
    include Api::JsonHelper
    include Api::FieldHelper

    before_filter :authenticate_api_user!
    before_filter :authenticate_site_user!, except: [:create, :feed]

    expose(:site) { Site.find(params[:id])}
    expose(:collection) { site.collection if site.present? }

    def create
      collection = Collection.find(params[:id])
      site_params = field_parse(collection, JSON.parse(params[:site]))

      site = collection.sites.new(user: current_user)
      site.validate_and_process_parameters(site_params, current_user)
      site.assign_default_values_for_create

      if site.valid? && site.save!
        current_user.site_count += 1
        render_json site, status: 200
      else
        render_error_response_422(site.errors.messages)
      end
    end

    def show
      search = new_search

      search.id(site.id)
      @result = search.api_results[0]

      respond_to do |format|
        format.rss
        format.json { render_json site_item_json(@result) }
      end
    end

    def feed
      collection = Collection.find(params[:id])
      sites = collection.sites.where("id >= ?", params[:offset_id].to_i)
      
      render :json => {:sites => sites}
    end

    def histories
      histories = site.histories.includes(:user).select('site_histories.*, users.email').references(:user)
      histories = if version = params[:version]
        histories.where(version: version)
      else
        histories.order('version ASC')
      end
      respond_to do |format|
        format.json { render_json histories.map{|h| h.attributes.merge({user: h.user.try(:email)})} }
      end
    end

    def update_property
      field = site.collection.fields.where_es_code_is params[:es_code]
      site.user = current_user
      authorize! :update_site_property, field, message: "Not authorized to edit site"
      updated = site.update_single_property!(params[:es_code], params[:value])
      if updated
        render_json(site, :status => 200)
      else
        error_message = site.errors[:properties][0][params[:es_code]]
        render_error_response_422(error_message)
      end
    end

    def destroy
      authorize! :delete, site, message: "Not authorized to delete site"
      site.user = current_user
      if site.destroy
        head :ok
      else
        render_generic_error_response("Could not delete site")
      end
    end

    def partial_update
      site_params = JSON.parse params[:site]
      site.user = current_user
      site.validate_and_process_parameters(site_params, current_user)

      render_update_response(site)
    end

    def update
      authorize! :update, site, message: "Not authorized to perform a full update on site"
      site_params = JSON.parse params[:site]
      site.user = current_user
      site.properties_will_change!
      site.attributes = site.decode_properties_from_ui(site_params)

      render_update_response(site)
    end

    def index
      builder = Collection.filter_sites(params)
      sites_size = builder.size
      sites_by_page  = Collection.filter_page(params[:limit], params[:offset], builder)
      render :json => {:sites => sites_by_page, :total => sites_size}
    end

    private

    def render_update_response(site)
      if site.valid? && site.save!
        render_json(site, status: 200)
      else
        render_error_response_422(site.errors.messages)
      end
    end
  end
end
