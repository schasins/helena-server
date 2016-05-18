class ColumnsController < ApplicationController

  def index
    @columns = Column.all
  end

end