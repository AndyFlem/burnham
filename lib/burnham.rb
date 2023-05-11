# frozen_string_literal: true

require_relative "burnham/version"

module Burnham
  class Model
    attr_reader :frames, :name

    def initialize(name)
      @name=name
      @frames = Hash.new
    end

    def create_frame(params)
      params[:model] = self
      frame = Frame.new(params)
      @frames[frame.ref] = frame
      frame
    end
  end

  class Frame
    attr_reader :name, :model, :ref

    def initialize(params)
      @model = params[:model]
      @name=params[:name]
      @ref = params[:ref]
    end

  end
end
