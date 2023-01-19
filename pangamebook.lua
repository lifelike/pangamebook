-- pandoc filter to turn headers and links into numbers
-- Copyright 2021-2023 Pelle Nilsson
-- MIT License
-- source: https://github.com/lifelike/pangamebook

-- version: 1.5.0 (2023-01-20)
-- fossil hash: f223851d094c9358feefd5c0a5a74506c98fdb14873dfab5afc23664a326ea87

local nr = 1
local mapped = {}

local strong_links = false
local link_pre = ''
local link_post = ''

function get_nr_for_header(text, identifier)
  local key = "#" .. identifier
  local name_nr = tonumber(text)
  if name_nr ~= nil then
    if name_nr >= nr then
       mapped[key] = name_nr
       nr = name_nr + 1
    else
       print("ERROR: Section number " .. name_nr
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
   local first = one_string_from_block(el)
   local s,e = string.find(first, "[a-z][a-z_0-9]*")
   return (s == 1 and e == string.len(first))
end

function is_number_section_name(el)
   local first = one_string_from_block(el)
   local as_number = tonumber(first)
   return as_number ~= null and as_number >= 1
end

function shuffle_insert(target, sections)
   while #sections > 0 do
      local i = math.random(1, #sections)
      local section = table.remove(sections, i)
      for i,v in ipairs(section) do
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
   value = meta[name]
   if value ~= nil then
      return value
   end
   return default
end

function from_meta_string(meta, name, default)
   value = meta[name]
   if value ~= nil then
      return value
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
                      #doc.blocks,
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

  if from_meta_bool(doc.meta, "gamebook-shuffle", true) then
     local seed_number = 2023
     local metadata_seed = doc.meta["gamebook-randomseed"]
     if metadata_seed ~= nil then
        local metadata_seed_number = tonumber(seed)
        if metadta_seed_number ~= nil then
           seed_number = metadta_seed_number
        end
     end
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
  if string.find(el.target, "://") ~= null then
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
