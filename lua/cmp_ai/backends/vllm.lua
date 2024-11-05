local requests = require('cmp_ai.requests')

VLLM = requests:new(nil)
local url = nil

function VLLM:new(o, params)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  self.params = vim.tbl_deep_extend('keep', params or o, {})
  url = self.params.url
  self.params.url = nil

  self.api_key = os.getenv('VLLM_API_KEY')
  if not self.api_key then
    self.api_key = 'NO_KEY'
  end
  self.headers = {
    'Authorization: Bearer ' .. self.api_key,
  }
  return o
end

function VLLM:complete(lines_before, lines_after, cb)
  if not self.api_key then
    vim.schedule(function()
      vim.notify('VLLM_API_KEY environment variable not set', vim.log.levels.ERROR)
    end)
    return
  end
  if url == nil then
    vim.schedule(function()
      vim.notify('URL not set', vim.log.levels.ERROR)
    end)
    return
  end
  local data = {
    prompt = {
      '<fim_prefix>' .. lines_before .. '<fim_suffix>' .. lines_after .. '<fim_middle>',
    },
  }
  data = vim.tbl_deep_extend('keep', data, self.params)
  self:Get(url, self.headers, data, function(answer)
    local new_data = {}
    if answer.choices then
      for _, response in ipairs(answer.choices) do
        local entry = response.text:gsub('<|end_of_text|>', '')
        entry = entry:gsub('```', '')
        table.insert(new_data, entry)
      end
    end
    cb(new_data)
  end)
end

function VLLM:test()
  self:complete('def factorial(n)\n    if', '    return ans\n', function(data)
    dump(data)
  end)
end

return VLLM
