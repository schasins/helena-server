json.array! @programs do |program|
    json.name program.name
    json.date program.updated_at.strftime("%s")
    json.id program.id
end