-- For explanation see https://iterm2.com/images.html
-- 2016 Sergey Zagoruyko

local iterm = {}
require 'image'
local base64 = require 'base64'
local ffi = require 'ffi'

local function print_osc()
   if os.getenv'TERM' == 'screen' then
      io.write'\27Ptmux;\27\27]'
   else
      io.write'\27]'
   end
end

local function print_st()
   if os.getenv'TERM' == 'screen' then
      io.write'\a\27\\'
   else
      io.write'\a'
   end
end

local function getBase64FromFile(filename)
   -- load the image back as binary blob
   local f = assert(torch.DiskFile(filename,'r',true)):binary();
   f:seekEnd();
   local size = f:position()-1
   f:seek(1)
   local buf = torch.CharStorage(size);
   assert(f:readChar(buf) == size, 'wrong number of bytes read')
   f:close()
   local enc = base64.encode(ffi.string(torch.data(buf), size))
   return enc, size
end

local function display(filename)
   local enc, size = getBase64FromFile(filename)
   print_osc()
   io.write'1337;File='
   io.write('name='..base64.encode(filename)..';')
   io.write('size='..size..';')
   io.write('inline=1:')
   io.write(enc)
   print_st()
end

function iterm.image(img, opts)
   if torch.type(img) == 'string' then -- assume that it is path
      display(img)
   elseif torch.isTensor(img) or torch.type(img) == 'table' then
      opts = opts or {padding=2}
      opts.input = img
      local imgDisplay = image.toDisplayTensor(opts)
      if imgDisplay:dim() == 2 then 
	 imgDisplay = imgDisplay:view(1, imgDisplay:size(1), imgDisplay:size(2))
      end
      local tmp = os.tmpname() .. '.png'
      image.save(tmp, imgDisplay)
      display(tmp)
      os.execute('rm -f ' .. tmp)
   else
      error('unhandled type in iterm.image:' .. torch.type(img))
   end
end

return iterm
