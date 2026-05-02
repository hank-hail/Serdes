--!strict
--!native

const Core = require'./Core'

const resize = Core.resize

type Writer = Core.Writer
type Reader = Core.Reader
type Codec = Core.Codec<number>

const MAX_I32 = Core.MAX_I32
const MIN_I32 = Core.MIN_I32

return table.freeze{
	write = function(self: Codec, writer: Writer, value: number): ()
		if type(value) ~= "number" then
			error(`Serdes.i32 expected number, got {type(value)} instead`, 3)
		end

		if value % 1 ~= 0 or value < MIN_I32 or value > MAX_I32 then
			error(`Serdes.i32 expected integer between {MIN_I32} and {MAX_I32}, got {value}`, 3)
		end

		const offset = writer.offset

		if offset + 4 > writer.capacity then
			resize(writer, 4)
		end

		writer.offset = offset + 4
		buffer.writei32(writer.buffer, offset, value)
	end,

	read = function(self: Codec, reader: Reader): number
		const offset = reader.offset

		if offset + 4 > reader.length then
			error(`Serdes read out of bounds. Needed 4 bytes at offset {offset}.`, 3)
		end

		reader.offset = offset + 4

		return buffer.readi32(reader.buffer, offset)
	end,

	min_size = 4,
	size = 4,
} :: Codec
