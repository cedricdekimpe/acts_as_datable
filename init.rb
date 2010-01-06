require 'acts_as_datable'
ActiveRecord::Base.send :include, Shooter::Acts::Datable
ActionView::Base.send :include, ActsAsDatable::ActsAsDatableHelpers