module Dogscaler
  class Check
    include Virtus.model
    include Logging
    NoPointsSetError  = Class.new(StandardError)
    NoResultsSetError  = Class.new(StandardError)

    attribute :scale_up_threshhold, Integer
    attribute :scale_down_threshhold, Integer
    attribute :transform, String, :default => 'avg'
    attribute :points, Array, :default => []
    attribute :result, Float

    def status
      raise NoResultSetError, 'No results set on this object' if not result
      if self.result > scale_up_threshhold
        logger.debug "Value: #{result} Threshold: #{scale_up_threshhold}."
        1
      elsif self.result < scale_down_threshhold
        logger.debug "Value: #{result} Threshold: #{scale_down_threshhold}."
        -1
      else
        logger.debug "Value: #{result} Max Threshold: #{scale_up_threshhold}."
        logger.debug "Value: #{result} Min Threshold: #{scale_down_threshhold}."
        0
      end
    end

    def reduce!
      raise NoPointsSetError, 'No points are set on this object' if points.empty?
      logger.debug "Apply transform #{transform}"
      case transform
      when 'avg'
        result = points.inject(0.0) { |sum,el| sum + el } / points.size
      when 'max'
        result = points.max
      when 'min'
        result = points.min
      when 'last'
        result = points[-1]
      when 'sum'
        result = points.reduce(0, :+)
      when 'count'
        result = points.count
      else
        logger.error 'Invalid transform: #{transform}'
        exit 1
      end
      logger.debug "Transformed value #{result}"
      self.result = result
    end

  end
end
