-- HackerVibe for Linux :: conky draw hook. One conky process per widget; the widget name comes
-- from the HV_WIDGET environment variable (set by `hackervibe start`).
local DATA = os.getenv('HV_DATA') or ((os.getenv('HOME') or '') .. '/.local/share/hackervibe')
package.path = DATA .. '/lib/?.lua;' .. package.path

require 'cairo'
-- older conky builds ship the X11 surface helpers as a separate module; newer ones fold them into 'cairo'
pcall(require, 'cairo_xlib')

local hv = require 'hv'
local name = os.getenv('HV_WIDGET') or 'clock'
local widget = require('widgets.' .. name)

local last_err
function conky_main()
  if conky_window == nil then return end
  local w, h = conky_window.width, conky_window.height
  if w == nil or w < 2 or h < 2 then return end

  local cs = cairo_xlib_surface_create(conky_window.display, conky_window.drawable,
                                       conky_window.visual, w, h)
  local cr = cairo_create(cs)
  cairo_scale(cr, w / widget.W, h / widget.H)
  cairo_set_antialias(cr, CAIRO_ANTIALIAS_BEST)

  local ok, err = pcall(widget.draw, cr, hv)
  if not ok and err ~= last_err then
    last_err = err
    io.stderr:write('[hackervibe:' .. name .. '] ' .. tostring(err) .. '\n')
  end

  cairo_destroy(cr)
  cairo_surface_destroy(cs)
end
