class Program < ActiveRecord::Base
  has_many :program_uses_relations
  has_many :relations, through: :program_uses_relations

  def save_program_and_relations(relations)
    Program.transaction do
      self.relations = relations
      self.save
    end
  end

end
