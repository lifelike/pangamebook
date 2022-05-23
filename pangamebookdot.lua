-- pandoc filter to output Graphviz DOT graph from gamebook
-- Copyright 2021-2022 Pelle Nilsson
-- MIT License
-- source: https://github.com/lifelike/pangamebook

-- version: 1.2.1 (2022-05-24)
-- fossil hash: 9490b64197fcd8b1c85e3e075ee80486142d360cb997ba2b31ae4e44fa1e6f96

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
