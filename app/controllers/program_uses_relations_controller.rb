class ProgramUsesRelationsController < ApplicationController
  before_action :set_program_uses_relation, only: [:show, :edit, :update, :destroy]

  # GET /program_uses_relations
  # GET /program_uses_relations.json
  def index
    @program_uses_relations = ProgramUsesRelation.all
  end

  # GET /program_uses_relations/1
  # GET /program_uses_relations/1.json
  def show
  end

  # GET /program_uses_relations/new
  def new
    @program_uses_relation = ProgramUsesRelation.new
  end

  # GET /program_uses_relations/1/edit
  def edit
  end

  # POST /program_uses_relations
  # POST /program_uses_relations.json
  def create
    @program_uses_relation = ProgramUsesRelation.new(program_uses_relation_params)

    respond_to do |format|
      if @program_uses_relation.save
        format.html { redirect_to @program_uses_relation, notice: 'Program uses relation was successfully created.' }
        format.json { render :show, status: :created, location: @program_uses_relation }
      else
        format.html { render :new }
        format.json { render json: @program_uses_relation.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /program_uses_relations/1
  # PATCH/PUT /program_uses_relations/1.json
  def update
    respond_to do |format|
      if @program_uses_relation.update(program_uses_relation_params)
        format.html { redirect_to @program_uses_relation, notice: 'Program uses relation was successfully updated.' }
        format.json { render :show, status: :ok, location: @program_uses_relation }
      else
        format.html { render :edit }
        format.json { render json: @program_uses_relation.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /program_uses_relations/1
  # DELETE /program_uses_relations/1.json
  def destroy
    @program_uses_relation.destroy
    respond_to do |format|
      format.html { redirect_to program_uses_relations_url, notice: 'Program uses relation was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_program_uses_relation
      @program_uses_relation = ProgramUsesRelation.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def program_uses_relation_params
      params.require(:program_uses_relation).permit(:program_id, :relation_id)
    end
end
