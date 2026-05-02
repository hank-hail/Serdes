--!strict
--!native

const Core = require'./Core'

const resize = Core.resize

type Writer = Core.Writer
type Reader = Core.Reader
type Codec = Core.Codec<boolean>

return table.freeze{
	write = function(self: Codec, writer: Writer, value: boolean): ()
		if type(value) ~= "boolean" then
			error(`Serdes.bool expected boolean, got {type(value)} instead`, 3)
		end

		const offset = writer.offset

		if offset + 1 > writer.capacity then
			resize(writer, 1)
		end
		
		writer.offset = offset + 1

		buffer.writeu8(writer.buffer, offset, value and 1 or 0)
	end,

	read = function(self: Codec, reader: Reader): boolean
		const offset = reader.offset

		if offset + 1 > reader.length then
			error(`Serdes read out of bounds. Needed 1 bytes at offset {offset}.`, 3)
		end

		const value = buffer.readu8(reader.buffer, offset)
		reader.offset = offset + 1

		if value == 0 then
			return false
		elseif value == 1 then
			return true
		end

		error(`Serdes.bool got invalid encoded value {value}`, 3)
	end,

	min_size = 1,
	size = 1,
} :: Codec
