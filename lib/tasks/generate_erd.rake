desc "Generate Entity Relationship Diagram"
task generate_erd: :environment do
  system "erd --inheritance --filetype=dot --direct --attributes=foreign_keys,content"
  system "dot -Tpng erd.dot > erd.png"
  File.delete("erd.dot")
end
