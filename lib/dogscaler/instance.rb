module Dogscaler
  class Instance
    NoPointsSetError  = Class.new(StandardError)
    NoResultsSetError  = Class.new(StandardError)

    include Virtus.model
    include Logging
    attribute :name, String
    attribute :query, String
    attribute :scale_up_threshhold, Integer
    attribute :scale_down_threshhold, Integer
    attribute :max_instances, Integer
    attribute :min_instances, Integer
    attribute :grow_by, Integer, :default => 1
    attribute :shrink_by, Integer, :default => 1
    attribute :autoscale_group, String
    attribute :transform, String, :default => 'avg'
    attribute :points, Array, :default => []
    attribute :result, Float
    attribute :capacity, Integer
    attribute :asg_tag_filters, Hash

    def reduce!
      raise NoPointsSetError, 'No points are set on this object' if points.empty?
      logger.debug "Apply transform #{transform}"
      case transform
        when 'avg'
          self.result = points.inject(0.0) { |sum,el| sum + el } / points.size
        when 'max'
          self.result = points.max
        when 'min'
          self.result = points.min
        when 'last'
          self.result = points[-1]
        when 'sum'
          self.result = points.reduce(0, :+)
        when 'count'
          self.result = points.count
        else
          logger.error 'Invalid transform: #{transform}'
          exit 1
      end
      logger.debug "Transformed value #{result}"
      result
    end

    def status
      raise NoResultSetError, 'No results set on this object' if not result
      if result > scale_up_threshhold
        logger.debug "Value: #{result} Threshold: #{scale_up_threshhold}."
        logger.debug "Would scale up by #{grow_by} instances."
        'grow'
      elsif result < scale_down_threshhold
        logger.debug "Value: #{result} Threshold: #{scale_down_threshhold}."
        logger.debug "Would scale down by #{shrink_by} instances."
        'shrink'
      else
        logger.debug "Value: #{result} Max Threshold: #{scale_up_threshhold}."
        logger.debug "Value: #{result} Min Threshold: #{scale_down_threshhold}."
        'okay'
      end
    end

  end
end
