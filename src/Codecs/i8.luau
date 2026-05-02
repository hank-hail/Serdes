--!strict
--!native

const Core = require'./Core'

const resize = Core.resize

type Writer = Core.Writer
type Reader = Core.Reader
type Codec = Core.Codec<number>

const MAX_I8 = Core.MAX_I8
const MIN_I8 = Core.MIN_I8

return table.freeze{
	write = function(self: Codec, writer: Writer, value: number): ()
		if type(value) ~= "number" then
			error(`Serdes.i8 expected number, got {type(value)} instead`, 3)
		end

		if value % 1 ~= 0 or value < MIN_I8 or value > MAX_I8 then
			error(`Serdes.i8 expected integer between {MIN_I8} and {MAX_I8}, got {value}`, 3)
		end

		const offset = writer.offset

		if offset + 1 > writer.capacity then
			resize(writer, 1)
		end

		writer.offset = offset + 1
		buffer.writei8(writer.buffer, offset, value)
	end,

	read = function(self: Codec, reader: Reader): number
		const offset = reader.offset

		if offset + 1 > reader.length then
			error(`Serdes read out of bounds. Needed 1 bytes at offset {offset}.`, 3)
		end

		reader.offset = offset + 1

		return buffer.readi8(reader.buffer, offset)
	end,

	min_size = 1,
	size = 1,
} :: Codec
