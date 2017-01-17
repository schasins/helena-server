class ProgramsController < ApplicationController
  skip_before_action :protect_from_forgery, :only =>[:save_program] # save_relation is going to be coming from the Chrome extension, so can't get the CSRF token.  in future should consider whether we should require some kind of authentication for this
  protect_from_forgery with: :null_session, :only =>[:save_program]

  def index
    @programs = Program.all
  end

  def show
    program = Program.find(params[:id])
    render json: {program: program}
  end

  def save_program
    relation_objects = params[:relation_objects]
    relations = []
    relation_objects.each do |key, value|
      relations.push(Relation.save_relation(value))
    end

    programs = Program.where(id: params[:id])
    program = nil
    if programs.length > 0
      program = programs[0]
      program.name = params[:name]
      program.serialized_program = params[:serialized_program]
    else
      program = Program.create(params.permit(:serialized_program, :name))
    end
    program.save_program_and_relations(relations)

    render json: { program: program }
  end


end
