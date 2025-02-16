# frozen_string_literal: true
require "doorkeeper/config/abstract_builder"

module Doorkeeper
  class Config
    class Builder < AbstractBuilder
      def do_not_reuse_access_token
        @config.instance_variable_set('@reuse_access_token', false)
      end
    end

    # The controller Doorkeeper::ApplicationMetalController inherits from.
    # Defaults to ActionController::API.
    #
    # @param base_metal_controller [String] the name of the base controller
    option :base_metal_controller,
           default: "ApiGuardian::BaseMetalController"
  end
end

Doorkeeper.configure do
  # Change the ORM that doorkeeper will use (needs plugins)
  orm :active_record

  # This block will be called to check whether the resource owner is authenticated or not.
  resource_owner_from_credentials do
    owner = ApiGuardian.authenticate(:email, email: params[:username], password: params[:password])
    ApiGuardian.logger.warn 'User not found or credentials are invalid.' unless owner
    owner
  end

  resource_owner_from_assertion do
    owner = ApiGuardian.authenticate(params[:assertion_type], params[:assertion])
    ApiGuardian.logger.warn 'User not found or credentials are invalid.' unless owner
    owner
  end

  # If you want to restrict access to the web interface for adding oauth authorized applications,
  # you need to declare the block below.
  # admin_authenticator do
  #   # Put your admin authentication logic here.
  #   # Example implementation:
  #   Admin.find_by_id(session[:admin_id]) || redirect_to(new_admin_session_url)
  # end

  # Authorization Code expiration time (default 10 minutes).
  # authorization_code_expires_in 10.minutes

  # Access token expiration time (default 2 hours).
  # If you want to disable expiration, set this to nil.
  access_token_expires_in ApiGuardian.configuration.access_token_expires_in

  # Assign a custom TTL for implicit grants.
  # custom_access_token_expires_in do |oauth_client|
  #   oauth_client.application.additional_settings.implicit_oauth_expiration
  # end

  # Use a custom class for generating the access token.
  # https://github.com/doorkeeper-gem/doorkeeper#custom-access-token-generator
  access_token_generator 'Doorkeeper::JWT'

  # Reuse access token for the same resource owner within an application (disabled by default)
  # Rationale: https://github.com/doorkeeper-gem/doorkeeper/issues/383
  if ApiGuardian.configuration.reuse_access_token
    reuse_access_token
  else
    do_not_reuse_access_token
  end

  # Issue access tokens with refresh token (disabled by default)
  use_refresh_token

  # Provide support for an owner to be assigned to each registered application (disabled by default)
  # Optional parameter :confirmation => true (default false) if you want to enforce ownership of
  # a registered application
  # Note: you must also run the rails g doorkeeper:application_owner generator to provide the necessary support
  # enable_application_owner :confirmation => false

  # Define access token scopes for your provider
  # For more information go to
  # https://github.com/doorkeeper-gem/doorkeeper/wiki/Using-Scopes
  # default_scopes  :public
  # optional_scopes :write, :update

  # Change the way client credentials are retrieved from the request object.
  # By default it retrieves first from the `HTTP_AUTHORIZATION` header, then
  # falls back to the `:client_id` and `:client_secret` params from the `params` object.
  # Check out the wiki for more information on customization
  # client_credentials :from_basic, :from_params

  # Change the way access token is authenticated from the request object.
  # By default it retrieves first from the `HTTP_AUTHORIZATION` header, then
  # falls back to the `:access_token` or `:bearer_token` params from the `params` object.
  # Check out the wiki for more information on customization
  # access_token_methods :from_bearer_authorization, :from_access_token_param, :from_bearer_param

  # Change the native redirect uri for client apps
  # When clients register with the following redirect uri, they won't be redirected to any server and the
  # authorization code will be displayed within the provider.
  # The value can be any string. Use nil to disable this feature. When disabled, clients must provide a valid URL
  # (Similar behaviour: https://developers.google.com/accounts/docs/OAuth2InstalledApp#choosingredirecturi)
  #
  # native_redirect_uri 'urn:ietf:wg:oauth:2.0:oob'

  # Forces the usage of the HTTPS protocol in non-native redirect uris (enabled
  # by default in non-development environments). OAuth2 delegates security in
  # communication to the HTTPS protocol so it is wise to keep this enabled.
  #
  # force_ssl_in_redirect_uri !Rails.env.development?

  # Specify what grant flows are enabled in array of Strings. The valid
  # strings and the flows they enable are:
  #
  # "authorization_code" => Authorization Code Grant Flow
  # "implicit"           => Implicit Grant Flow
  # "password"           => Resource Owner Password Credentials Grant Flow
  # "client_credentials" => Client Credentials Grant Flow
  #
  # If not specified, Doorkeeper enables authorization_code and
  # client_credentials.
  #
  # implicit and password grant flows have risks that you should understand
  # before enabling:
  #   http://tools.ietf.org/html/rfc6819#section-4.4.2
  #   http://tools.ietf.org/html/rfc6819#section-4.4.3
  #
  grant_flows %w(assertion password)

  # Under some circumstances you might want to have applications auto-approved,
  # so that the user skips the authorization step.
  # For example if dealing with a trusted application.
  # skip_authorization do |resource_owner, client|
  #   client.superapp? or resource_owner.admin?
  # end

  # WWW-Authenticate Realm (default "Doorkeeper").
  realm ApiGuardian.configuration.realm
end

Doorkeeper::JWT.configure do
  # Set the payload for the JWT token. This should contain unique information
  # about the user.
  token_payload do |opts|
    user = ApiGuardian.configuration.user_class.find(opts[:resource_owner_id])
    iat = DateTime.current.utc.to_i
    {
      iss: ApiGuardian.configuration.jwt_issuer,
      iat: iat,
      exp: iat + opts[:expires_in],
      jti: Digest::MD5.hexdigest([SecureRandom.hex, iat].join(':')),
      sub: user.id,
      user: {
        id: user.id
      },
      permissions: user.role.permissions
    }
  end

  # Set the encryption secret. This would be shared with any other applications
  # that should be able to read the payload of the token.
  # Defaults to "secret"
  secret_key ApiGuardian.configuration.jwt_secret

  # If you want to use RS* encoding specify the path to the RSA key
  # to use for signing.
  secret_key_path ApiGuardian.configuration.jwt_secret_key_path

  # Specify encryption type. Supports any algorithim in
  # https://github.com/progrium/ruby-jwt
  encryption_method ApiGuardian.configuration.jwt_encryption_method
end
