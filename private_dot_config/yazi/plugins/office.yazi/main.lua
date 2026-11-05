-- Local Office previewer: first page of docx/xlsx/pptx/odt/... as an image.
-- libreoffice (headless) converts to a temporary PDF, pdftoppm renders it to a JPEG that is cached by yazi.
-- Needs `libreoffice` (cask, see Brewfile; `soffice` works too) and `poppler`. Written for yazi >= 25.5.

local M = {}

local function converter()
	for _, name in ipairs({ "libreoffice", "soffice" }) do
		local child = Command(name):arg("--version"):stdout(Command.NULL):stderr(Command.NULL):status()
		if child and child.success then
			return name
		end
	end
	return "soffice"
end

function M:peek(job)
	local cache = ya.file_cache(job)
	if not cache then
		return
	end
	local ok, err = self:preload(job)
	if not ok or err then
		return ya.preview_widget(job, ui.Text(tostring(err or "Preview failed")):area(job.area):wrap(ui.Wrap.YES))
	end
	ya.sleep(math.max(0, rt.preview.image_delay / 1000))
	return ya.image_show(cache, job.area)
end

function M:seek() end

function M:preload(job)
	local cache = ya.file_cache(job)
	if not cache or fs.cha(cache) then
		return true
	end

	local tmp = "/tmp/yazi-office-" .. ya.uid() .. "/"
	local pdf = tmp .. job.file.name:gsub("%.[^%.]+$", "") .. ".pdf"

	local lo, err = Command(converter())
		:arg({ "--headless", "--convert-to", "pdf", "--outdir", tmp, tostring(job.file.path or job.file.url) })
		:stdin(Command.NULL)
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:output()
	if not lo or not lo.status.success then
		return true, Err("LibreOffice conversion failed: %s", err or (lo and lo.stderr) or "")
	end

	local out, perr = Command("pdftoppm")
		:arg({ "-singlefile", "-jpeg", "-jpegopt", "quality=" .. rt.preview.image_quality, "-f", 1, pdf })
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:output()
	fs.remove("file", Url(pdf))
	if not out or not out.status.success then
		return true, Err("pdftoppm failed: %s", perr or (out and out.stderr) or "")
	end

	return fs.write(cache, out.stdout)
end

return M
