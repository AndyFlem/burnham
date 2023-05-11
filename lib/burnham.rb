# frozen_string_literal: true

require_relative "burnham/version"

module Burnham
  class Error < StandardError; end
  
  class Model
    @frames = Hash.new

    def add_frame(frame)
      @frames[frame.ref] = frame
    end
  end

  class Frame
    @name = ''
    @model = nil
    @ref = nil

    def initialize(params)
      @name=params[:name]
      @model = params[:model]
      @ref = params[:ref]
      model.add_frame(self)
    end

  end
end
