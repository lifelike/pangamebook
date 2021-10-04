-- pandoc filter to 
-- Copyright 2021 Pelle Nilsson

function name_from_header(b)
   local result = ""
   local found_text = false
   pandoc.walk_block(b, {
                        Str = function(s)
                           if found_text then
                              return ""
                           else
                              result = s.text
                           end
                        end
   })
   if (b.identifier == "section"
       or b.identifier:sub(1, 8) == "section-") then
      return result
   else
      return result .. "\\n" .. b.identifier
   end
end

function dot_link(from, to)
   return '"' .. from .. '" -> "' .. to .. '"\n'
end

function Pandoc(doc)
   if not FORMAT:match "plain" then
      return doc
   end
   local in_header = nil
   local identifiers = {}
   local output = "digraph gamebook {node[shape=box]\n"
   for i,el in pairs(doc.blocks) do
      if (el.t == "Header"
          and el.level == 1) then
         local name = name_from_header(el)
         identifiers["#" .. el.identifier] = name
      end
   end
   for i,el in pairs(doc.blocks) do
      if (el.t == "Header"
          and el.level == 1) then
         in_section = name_from_header(el)
      else if (el.t == "Para" and in_section) then
         for j,c in pairs(el.content) do
            if c.t == "Link" then
               local target = identifiers[c.target]
               if target then
                  output = output .. dot_link(in_section, target)
               end
            end
         end
      end
      end
   end
   output = output .. "}\n"
   local blocks = pandoc.Para(pandoc.Str(output))
   return pandoc.Pandoc(blocks, doc.meta)
   end

function Blocks(blocks)
  return blocks
end

return {
   {Pandoc = Pandoc},
}
