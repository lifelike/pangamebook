-- pandoc filter to output Graphviz DOT graph from gamebook
-- Copyright 2021-2022 Pelle Nilsson
-- MIT License
-- source: https://github.com/lifelike/pangamebook

-- version: 1.5.0 (2023-01-20)
-- fossil hash: f223851d094c9358feefd5c0a5a74506c98fdb14873dfab5afc23664a326ea87

function one_string_from_block(b)
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
   return result
end

function is_gamebook_section_header(el)
   if not (el.t == "Header"
           and el.level == 1) then
      return false
   end 
   local first = one_string_from_block(el)
   local as_number = tonumber(first)
   return as_number ~= null and as_number >= 1
end

function dot_label_for_header(b)
   local label = one_string_from_block(b)
   local identifier = b.identifier
   if not (identifier == "section"
       or identifier:sub(1, 8) == "section-") then
      label = label .. '\\n' .. identifier
   end
   return '"' .. identifier .. '" [label=\"' ..label .. '"];\n'
end

function dot_link(from, to)
   return '"' .. from .. '" -> "' .. to .. '";\n'
end

local endstyle = '[shape=doubleoctagon]'

function Pandoc(doc)
   if not FORMAT:match "plain" then
      return doc
   end
   local in_header = nil
   local links_out = false
   local identifiers = {}
   local output = "digraph gamebook {\nnode[shape=box];\n\n"
   for i,el in pairs(doc.blocks) do
      if is_gamebook_section_header(el) then
         output = output .. dot_label_for_header(el)
         identifiers["#" .. el.identifier] = el.identifier
      end
   end
   for i,el in pairs(doc.blocks) do
      if is_gamebook_section_header(el) then
         if in_section and not links_out then
            output = output .. '"' .. in_section .. '"' .. endstyle .. ';\n'
         end
         in_section = el.identifier
         links_out = false
      elseif el.t == "Para" and in_section then
         for j,c in pairs(el.content) do
            if c.t == "Link" then
               local target = identifiers[c.target]
               if target then
                  output = output .. dot_link(in_section, target)
                  links_out = true
               end
            end
         end
      end
   end
   if in_section and not links_out then
      output = output .. '"' .. in_section .. '"' .. endstyle .. ';\n'
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
