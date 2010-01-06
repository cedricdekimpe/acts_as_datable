module Shooter #:nodoc:
  module Acts #:nodoc:
    module Datable
      def self.included(base) #:nodoc:
        base.extend ClassMethods
      end
 
      module ClassMethods
        # == Configuration Options
        #
        # * <tt>on</tt> - attribute on the model that will be referenced for all queries (default: created_at)
        # * <tt>order</tt> - default order that results will be returned (default: DESC)
        
        def acts_as_datable(options = {})
          unless datable?
            cattr_accessor :datable_attribute, :sort_order, :conditions
            self.datable_attribute = options[:on] || :created_at
            self.sort_order = options[:order] || "DESC"
            self.conditions = options[:conditions] || "1==1"
          end
          include InstanceMethods
        end
 
        def datable?
          self.included_modules.include?(InstanceMethods)
        end
      end
 
      module InstanceMethods
        def self.included(base)
          base.extend ClassMethods
        end
        
        module ClassMethods
          # == ClassMethods
          #
          # * <tt>Model.years</tt> - returns an array of years for which Model record has been created. <tt>Post.years # => [2010, 2009]</tt>
          # * <tt>Model.months_of_year</tt> - returns an array of months of given year for which Model record has been created (default: current year). <tt>Post.months_of_year(2009) # => [01,03,04]</tt>
          
          def years
            find(:all, 
              :select => "YEAR(#{datable_attribute}) as year", 
              :order => "#{datable_attribute} #{sort_order}",
              :conditions => conditions,
              :group => "year"
            ).collect{|i| i.year }
          end
          
          def months_of_year(year = Date.today.year)
            find(:all, 
              :select => "MONTH(#{datable_attribute}) as month", 
              :order => "#{datable_attribute} #{sort_order}", 
              :group => "month", 
              :conditions => conditions_for_month(year)
            ).collect{|i| i.month}
          end
          
          def collection
            coll = Hash.new
            for year in years
              coll.store year, months_of_year(year)
            end
            return coll
          end
          
          private
          
          def conditions_for_month(year)
            default_conditions = ["YEAR(#{datable_attribute}) = ?", year]
            if conditions.nil? or conditions.empty?
              default_conditions
            else
              composed_conditions = []
              composed_conditions << "#{default_conditions.first} AND #{conditions.first}"
              conditions.delete_at(0)
              composed_conditions << year
              composed_conditions << conditions
            end
          end
          
          
        end
      end
    end
  end
end

module ActsAsDatable # :nodoc: all
  module ActsAsDatableHelpers
    def date_based_archive(collection)
      html = "<ul>"
      collection.each{|year,months| 
        html += "<li class='actsasdatable-year'>#{link_for_year(year)}"
        unless months.empty?
          html += "<ul class='actsasdatable-months'>"
          for month in months
            html += "<li class='actsasdatable-month'>#{link_for_month(month, year)}</li>"
          end
          html += "</ul>"
        end
        html += "</li>"
      }
      html += "</ul>"
    end
    
    def link_for_year(year)
      link_to(year, { :year => year, :month => nil }, :class => (params[:year].to_i == year.to_i and params[:month].nil?) ? "current" : nil)
    end
    
    def link_for_month(month, year)
      date = Date.new(year.to_i,month.to_i)
      link_to(l(date, :format => :month_name), { :year => year, :month => month }, :class => (params[:year].to_i == year.to_i and params[:month].to_i == month.to_i) ? "current" : nil)
    end
    
  end
end