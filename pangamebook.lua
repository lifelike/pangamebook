-- pandoc filter to turn headers and links into numbers
-- Copyright 2021-2024 Pelle Nilsson
-- MIT License
-- source: https://github.com/lifelike/pangamebook

-- version: 2.0.1 (2024-08-27)
-- fossil hash: ef2f6a804b30bbc48a2a5398565d7e607af1319b3fb28c346442eec2e77f00b1

local nr = 1
local mapped = {}

function get_nr_for_header(text, identifier)
  local key = "#" .. identifier
  local name_nr = tonumber(text)
  if name_nr ~= nil then
    if name_nr >= nr then
       mapped[key] = name_nr
       nr = name_nr + 1
    else
       io.stderr:write("ERROR: Section number " .. name_nr
                       .. " too low (expected >= " .. nr .. ")")
       os.exit(1)
    end
  else
    mapped[key] = nr
    nr = nr + 1
  end
  return mapped[key]
end

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

function is_valid_section_name(el)
   if gap >= 1 and is_number_section_name(el) then
      return true
   end
   local first = one_string_from_block(el)
   local s,e = string.find(first, "[a-z][a-z_0-9]*")
   return (s == 1 and e == string.len(first))
end

function is_number_section_name(el)
   local first = one_string_from_block(el)
   local as_number = tonumber(first)
   return as_number ~= nil and as_number >= 1
end

function shuffle_insert(target, sections)
   if gap < 1 then
      return shuffle_insert_random(target, sections)
   else
      return shuffle_insert_gap(target, sections)
   end
end

function shuffle_insert_gap(target, sections)
   local shuffled = {}
   local max = #sections
   for i,section in pairs(sections) do
      if is_number_section_name(section[1]) then
         local number = tonumber(one_string_from_block(section[1]))
         if shuffled[number] then
            io.stderr:write("ERROR: Two sections numbered " .. number .. "?")
            os.exit(1)
         end
         shuffled[number] = section
         table.remove(sections, i)
      end
   end
   if not shuffled[1] and #sections > 1 then
      local first = table.remove(sections, 1)
      shuffled[1] = first
   end
   local next_index = 1
   for _,section in pairs(sections) do
      next_index = get_free_index(shuffled, next_index + gap, max)
      shuffled[next_index] = section
      if next_index > max then
         next_index = get_free_index(shuffled, 1, max)
      end
   end
   for _,section in pairs(shuffled) do
      for _,v in ipairs(section) do
         table.insert(target, v)
      end
   end
end

function get_free_index(list, from, max)
   if from > max then
      from = 1
   end
   local i = from
   while i ~= from - 1 or (from == 1 and i == max) do
      if list[i] == nil then
         return i
      end
      i = i + 1
      if i > max then
         i = 1
      end
   end
   io.stderr:write("ERROR: Failed to find free index from " .. from
                   .. "(max " .. max .. ") (should never happen)")
   os.exit(1)
end

function shuffle_insert_random(target, sections)
   while #sections > 0 do
      local i = math.random(1, #sections)
      local section = table.remove(sections, i)
      for _,v in ipairs(section) do
         table.insert(target, v)
      end
   end
end

function insert_sections(sections,
                         section_start,
                         section_end,
                         blocks)
   local section = {}
   for j=section_start,section_end-1 do
      table.insert(section, blocks[j])
   end
   table.insert(sections, section)
end

function from_meta_bool(meta, name, default)
   local value = meta[name]
   if type(value) == 'boolean' then
      return value
   end
   if value ~= nil and value.t == "MetaBool" then
      return value.c
   end
   return default
end

function from_meta_string(meta, name, default)
   local value = meta[name]
   if value ~= nil then
      return pandoc.utils.stringify(value)
   end
   return default
end

function from_meta_int(meta, name, default)
   if meta[name] then
      local value = pandoc.utils.stringify(meta[name])
      return tonumber(value)
   end
   return default
end

function shuffle_blocks(doc)
   local sections = {}
   local first_section_i = 0
   local current_section_start = -1
   local blocks = {}

   for i,el in pairs(doc.blocks) do
      if (el.t == "Header"
          and el.level == 1) then
         if current_section_start >= 0 then
            insert_sections(sections,
                            current_section_start,
                            i,
                            doc.blocks)
         end
         if is_valid_section_name(el) then
            current_section_start = i
         else
            if #sections > 0 then
               shuffle_insert(blocks, sections)
               sections = {}
            end
            table.insert(blocks, el)
            current_section_start = -1
         end
      else
         if current_section_start < 0 then
            table.insert(blocks, el)
         end
      end
   end
   if current_section_start >= 0 then
      insert_sections(sections,
                      current_section_start,
                      #doc.blocks + 1,
                      doc.blocks)
   end
   if #sections > 0 then
      shuffle_insert(blocks, sections)
   end
   return blocks
end

function Pandoc(doc)
  number_sections = from_meta_bool(doc.meta, "gamebook-numbers", true)
  strong_links = from_meta_bool(doc.meta, "gamebook-strong-links", true)
  link_pre = from_meta_string(doc.meta, "gamebook-pre-link", "")
  link_post = from_meta_string(doc.meta, "gamebook-post-link", "")
  gap = from_meta_int(doc.meta, "gamebook-gap", 23)

  if from_meta_bool(doc.meta, "gamebook-shuffle", true) then
     local seed_number = from_meta_int(doc.meta, "gamebook-randomseed", 2023)
     math.randomseed(seed_number)
     return pandoc.Pandoc(shuffle_blocks(doc), doc.meta)
  else
     return doc
  end
end

function Header(el)
  if (el.level ~= 1
      or not number_sections
      or not (is_valid_section_name(el)
              or is_number_section_name(el))) then
     return el
  end
  local first = one_string_from_block(el)
  local as_number
  local found = false
  local replaced = false
  local identifier = el.identifier
  return pandoc.walk_block(el, {
    Str = function(b)
            if replaced then
              return pandoc.Str("")
            else
              replaced = true
              local nr = get_nr_for_header(b.text, identifier)
              return pandoc.Str(nr)
            end
          end
    })
end

function Link(el)
  if string.find(el.target, "://") ~= nil then
     return
  end
  local nr = mapped[el.target]
  local content
  if nr == nil then
    content = pandoc.Str(link_pre .. el.target .. link_post)
  else
    content = pandoc.Str(link_pre .. nr .. link_post)
  end
  if strong_links then
     content = pandoc.Strong(content)
  end
  return pandoc.Link(content, el.target)
end

function Blocks(blocks)
  return blocks
end

function Meta(meta)
   local mapped_meta = {}
   for k, v in pairs(mapped) do
      mapped_meta[k] = tostring(v)
   end
   meta["pangamebook-mapping"] = mapped_meta
   return meta
end

return {
   {Pandoc = Pandoc},
   {Header = Header},
   {Link = Link},
   {Meta = Meta}
}
