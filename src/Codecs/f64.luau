--!strict
--!native

const Core = require'./Core'

const resize = Core.resize

type Writer = Core.Writer
type Reader = Core.Reader
type Codec = Core.Codec<number>

const INF = Core.INF

return table.freeze{
	write = function(self: Codec, writer: Writer, value: number): ()
		if type(value) ~= "number" then
			error(`Serdes.f64 expected number, got {type(value)} instead`, 3)
		end

		if value ~= value or value == INF or value == -INF then
			error(`Serdes.f64 expected finite f64 number, got {value}`, 3)
		end

		const offset = writer.offset

		if offset + 8 > writer.capacity then
			resize(writer, 8)
		end
		
		writer.offset = offset + 8
		buffer.writef64(writer.buffer, offset, value)
	end,

	read = function(self: Codec, reader: Reader): number
		const offset = reader.offset

		if offset + 8 > reader.length then
			error(`Serdes read out of bounds. Needed 8 bytes at offset {offset}.`, 3)
		end

		reader.offset = offset + 8

		return buffer.readf64(reader.buffer, offset)
	end,

	min_size = 8,
	size = 8,
} :: Codec
