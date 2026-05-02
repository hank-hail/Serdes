--!strict
--!native

const Core = require'./Core'

const resize = Core.resize

type Writer = Core.Writer
type Reader = Core.Reader
type Codec = Core.Codec<number>

const F32_MAX = Core.F32_MAX

return table.freeze{
	write = function(self: Codec, writer: Writer, value: number): ()
		if type(value) ~= "number" then
			error(`Serdes.f32 expected number, got {type(value)} instead`, 3)
		end

		if value ~= value or value < -F32_MAX or value > F32_MAX then
			error(`Serdes.f32 expected finite f32 number, got {value}`, 3)
		end

		const offset = writer.offset

		if offset + 4 > writer.capacity then
			resize(writer, 4)
		end

		writer.offset = offset + 4
		buffer.writef32(writer.buffer, offset, value)
	end,

	read = function(self: Codec, reader: Reader): number
		const offset = reader.offset

		if offset + 4 > reader.length then
			error(`Serdes read out of bounds. Needed 4 bytes at offset {offset}.`, 3)
		end

		reader.offset = offset + 4

		return buffer.readf32(reader.buffer, offset)
	end,

	min_size = 4,
	size = 4,
} :: Codec
