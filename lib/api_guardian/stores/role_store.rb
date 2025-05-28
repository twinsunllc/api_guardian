module ApiGuardian
  module Stores
    class RoleStore < Base
      def self.default_role
        Role.default_roles.first
      end
    end
  end
end
