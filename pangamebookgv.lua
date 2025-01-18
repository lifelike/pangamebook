-- pandoc filter to output Graphviz graph from gamebook
-- Copyright 2021-2025 Pelle Nilsson
-- MIT License
-- source: https://github.com/lifelike/pangamebook

-- version: 2.1.0 (2025-01-18)
-- fossil hash: 587bef4d34ea2fe36bd343f233615638dc18efecbaa3ff3af89aa62890bec8bf

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
           and el.level == level) then
      return false
   end
   local first = one_string_from_block(el)
   local as_number = tonumber(first)
   return as_number ~= null and as_number >= 1
end

function gv_label_for_header(b)
   local label = one_string_from_block(b)
   local identifier = b.identifier
   if not (identifier == "section"
       or identifier:sub(1, 8) == "section-") then
      label = label .. '\\n' .. identifier
   end
   root = ''
   if tonumber(label) == 1 then
      root = ',root=true'
   end
   return '"' .. identifier .. '" [label=\"' ..label .. '"' .. root .. '];\n'
end

function gv_link(from, to)
   return '"' .. from .. '" -> "' .. to .. '";\n'
end

local endstyle = '[shape=doubleoctagon]'

function from_meta_int(meta, name, default)
   if meta[name] then
      local value = pandoc.utils.stringify(meta[name])
      return tonumber(value)
   end
   return default
end

function Pandoc(doc)
   if not FORMAT:match "plain" then
      return doc
   end

   level = from_meta_int(doc.meta, "gamebook-header-level", 1)

   local in_header = nil
   local links_out = false
   local identifiers = {}
   local output = "digraph gamebook {\nnode[shape=box];\n\n"
   for i,el in pairs(doc.blocks) do
      if is_gamebook_section_header(el) then
         output = output .. gv_label_for_header(el)
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
      elseif in_section then
         pandoc.walk_block(el, {
            Link = function(c)
               local target = identifiers[c.target]
               if target then
                  output = output .. gv_link(in_section, target)
                  links_out = true
               end
            end
         })
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
