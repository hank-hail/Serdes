--!strict
--!native

const Core = require'./Core'

const resize = Core.resize

type Writer = Core.Writer
type Reader = Core.Reader
type Codec = Core.Codec<number>

const MAX_I16 = Core.MAX_I16
const MIN_I16 = Core.MIN_I16

return table.freeze{
	write = function(self: Codec, writer: Writer, value: number): ()
		if type(value) ~= "number" then
			error(`Serdes.i16 expected number, got {type(value)} instead`, 3)
		end

		if value % 1 ~= 0 or value < MIN_I16 or value > MAX_I16 then
			error(`Serdes.i16 expected integer between {MIN_I16} and {MAX_I16}, got {value}`, 3)
		end

		const offset = writer.offset

		if offset + 2 > writer.capacity then
			resize(writer, 2)
		end

		writer.offset = offset + 2
		buffer.writei16(writer.buffer, offset, value)
	end,

	read = function(self: Codec, reader: Reader): number
		const offset = reader.offset

		if offset + 2 > reader.length then
			error(`Serdes read out of bounds. Needed 2 bytes at offset {offset}.`, 3)
		end

		reader.offset = offset + 2

		return buffer.readi16(reader.buffer, offset)
	end,

	min_size = 2,
	size = 2,
} :: Codec
