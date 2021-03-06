module Lti
  class RegistrationController < ApplicationController
    layout 'lti'

    include RailsLti2Provider::ControllerHelpers
    include LtiHelper

    skip_authorization_check
    protect_from_forgery except: :save_capabilities
    after_action :disable_xframe_header

    def register
      #tool_setting_service = %w(LtiLink.custom.url ToolProxyBinding.custom.url ToolProxy.custom.url)
      filter_out = [
          IMS::LTI::Models::Messages::BasicLTILaunchRequest::MESSAGE_TYPE,
          IMS::LTI::Models::Messages::ToolProxyReregistrationRequest::MESSAGE_TYPE
      ]

      tcp = get_consumer_profile

      #get a list of resources and capabilities
      @resources = "Room"

      @capabilities = {}
      # encrypt before sending
      key = ActiveSupport::KeyGenerator.new('password').generate_key(Rails.application.secrets.secret_key_base, 32)
      crypt = ActiveSupport::MessageEncryptor.new(key)
      @reg_pw = crypt.encrypt_and_sign(params['reg_password'])
    end

    def save_capabilities
      # decrypt reg_password before performing registration request
      key = ActiveSupport::KeyGenerator.new('password').generate_key(Rails.application.secrets.secret_key_base, 32)
      crypt = ActiveSupport::MessageEncryptor.new(key)
      decrypted_pw = crypt.decrypt_and_verify(params['reg_password'])
      params['reg_password'] = decrypted_pw

      registration_request
      lti_authentication if reregistration?
      @registration.save!
      parameters = {}

      #Set the tool settings, proxy and profile for registration
      tool_settings = (params['tool_settings'].present? && JSON.parse(params['tool_settings'])) || nil
      tool_proxy = @registration.tool_proxy
      tool_profile = tool_proxy.tool_profile

      #Fix of the tool profile base url, now correctly matches root.url
      tool_profile.base_url_choice.find{ |choice| choice.default_message_url != '' }.default_base_url = root_url.chop
      add_reregistration_handler!(@registration, tool_profile)

      # make changes to settings to resource handler
      rh = tool_profile.resource_handler.first
      mh = rh.message.first
      mh.parameter = set_consumer_params(@registration.tool_consumer_profile.capabilities_offered, parameters.keys)

      # custom parameters are set here
      tool_proxy.custom = tool_settings if tool_settings
      # set the single resource handler profile
      tool_proxy.tool_profile.resource_handler = [rh]
      #update the registration and the redirect to submit_proxy
      @registration.update(tool_proxy_json: tool_proxy.to_json)
      redirect_to lti_submit_proxy_path(@registration.id)
    end

    def submit_proxy
      begin
        registration = RailsLti2Provider::Registration.find(params[:registration_uuid])
        proxy = register_proxy(registration)
        # update the tool with the registration account and resource type
        resource_code = registration.tool_proxy.tool_profile.resource_handler.as_json.first["resource_type"]["code"]

        registration.tool.update(resource_type: resource_code)

        redirect_to_consumer(proxy)
      rescue IMS::LTI::Errors::ToolProxyRegistrationError => e
        @error = {
            tool_proxy_guid: registration.tool_proxy.tool_proxy_guid,
            response_status: e.response_status,
            response_body: e.response_body
        }
      end
    end

    def add_reregistration_handler!(registration, tool_profile)
      if (registration.tool_consumer_profile.capability_offered.include?(IMS::LTI::Models::Messages::ToolProxyReregistrationRequest::MESSAGE_TYPE))
        rereg_mh = IMS::LTI::Models::MessageHandler.new(
            message_type: IMS::LTI::Models::Messages::ToolProxyReregistrationRequest::MESSAGE_TYPE,
            path: lti_tool_reregistration_path
        )
        tool_profile.message = [rereg_mh]
      end
    end

    protected

    def reregistration?
      params[:lti_message_type] ==  IMS::LTI::Models::Messages::ToolProxyReregistrationRequest::MESSAGE_TYPE
    end

    private

    def get_consumer_profile
      reg_request = IMS::LTI::Models::Messages::Message.generate(params.except(:controller, :action))
      tcp = IMS::LTI::Services::ToolProxyRegistrationService.new(reg_request).tool_consumer_profile
      tcp
    end

    def set_consumer_params(offered_params, opt_params)
      # ensure that REQUIRED_PARAMETERS are valid
      required = LTI2_REQUIRED_PARAMETERS.select { |p| offered_params.include?(p) }
      parameters = required.push(opt_params).flatten

      parameters = parameters.map do |var|
        IMS::LTI::Models::Parameter.new(name: var.downcase.gsub('.','_'), variable: var)
      end
      parameters
    end
  end
end
