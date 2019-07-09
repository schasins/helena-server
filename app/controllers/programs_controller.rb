class ProgramsController < ApplicationController
  # save_program is going to be coming from the Chrome extension, so can't get the CSRF token.  in future should consider whether we should require some kind of authentication for this
  protect_from_forgery with: :null_session, :only =>[:save_program], raise: false

  def index
    tool_id = params[:tool_id]
    puts tool_id
    if (!tool_id || tool_id == "")
      @programs = Program.where(hidden: nil).select("name, id, updated_at, associated_string").order(updated_at: :desc)
    else
      @programs = Program.where(hidden: nil, tool_id: params[:tool_id]).select("name, id, updated_at, associated_string").order(updated_at: :desc)
    end
  end

  def show
    program = Program.find(params[:id])
    render json: {program: program}
  end

  def save_program
    puts "save_program received time", Time.now().to_i

    relation_objects = params[:relation_objects]
    relations = []
    if relation_objects
      relation_objects.each do |key, value|
        relations.push(Relation.save_relation(value))
      end
    end

    program = nil
    programs = nil
    if params[:id]
      programs = Program.where(id: params[:id])
    end
    if programs && programs.length > 0 && programs[0].name == params[:name]
        # for now, if names are same, assume we should overwrite the old one
        program = programs[0]
        program.serialized_program = params[:serialized_program]
        program.associated_string = params[:associated_string]
    else
        # if no saved program with the target id or if saved program didn't share name, need to make a fresh one
      program = Program.create(params.permit(:serialized_program, :name, :tool_id, :associated_string))
    end
    program.save_program_and_relations(relations)

    render json: { program: program }
  end


end
