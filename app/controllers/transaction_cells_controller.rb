class TransactionCellsController < ApplicationController
  before_action :set_transaction_cell, only: [:show, :edit, :update, :destroy]

  # GET /transaction_cells
  # GET /transaction_cells.json
  def index
    @transaction_cells = TransactionCell.all
  end

  # GET /transaction_cells/1
  # GET /transaction_cells/1.json
  def show
  end

  # GET /transaction_cells/new
  def new
    @transaction_cell = TransactionCell.new
  end

  # GET /transaction_cells/1/edit
  def edit
  end

  # POST /transaction_cells
  # POST /transaction_cells.json
  def create
    @transaction_cell = TransactionCell.new(transaction_cell_params)

    respond_to do |format|
      if @transaction_cell.save
        format.html { redirect_to @transaction_cell, notice: 'Transaction cell was successfully created.' }
        format.json { render :show, status: :created, location: @transaction_cell }
      else
        format.html { render :new }
        format.json { render json: @transaction_cell.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /transaction_cells/1
  # PATCH/PUT /transaction_cells/1.json
  def update
    respond_to do |format|
      if @transaction_cell.update(transaction_cell_params)
        format.html { redirect_to @transaction_cell, notice: 'Transaction cell was successfully updated.' }
        format.json { render :show, status: :ok, location: @transaction_cell }
      else
        format.html { render :edit }
        format.json { render json: @transaction_cell.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /transaction_cells/1
  # DELETE /transaction_cells/1.json
  def destroy
    @transaction_cell.destroy
    respond_to do |format|
      format.html { redirect_to transaction_cells_url, notice: 'Transaction cell was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_transaction_cell
      @transaction_cell = TransactionCell.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def transaction_cell_params
      params.require(:transaction_cell).permit(:transaction_id, :attr_value)
    end
end
