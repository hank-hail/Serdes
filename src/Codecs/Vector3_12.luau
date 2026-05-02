--!strict
--!native

const Core = require'./Core'

const resize = Core.resize

type Writer = Core.Writer
type Reader = Core.Reader
type Codec = Core.Codec<Vector3>

return table.freeze{
	write = function(self: Codec, writer: Writer, value: Vector3): ()
		if typeof(value) ~= "Vector3" then
			error(`Serdes.Vector3_f32 expected Vector3, got {typeof(value)} instead`, 3)
		end

		const offset = writer.offset
		const writer_buffer = writer.buffer

		if offset + 12 > writer.capacity then
			resize(writer, 12)
		end

		writer.offset = offset + 12

		buffer.writef32(writer_buffer, offset, value.X)
		buffer.writef32(writer_buffer, offset + 4, value.Y)
		buffer.writef32(writer_buffer, offset + 8, value.Z)
	end,

	read = function(self: Codec, reader: Reader): Vector3
		const offset = reader.offset

		if offset + 12 > reader.length then
			error(`Serdes read out of bounds. Needed 12 bytes at offset {offset}.`, 3)
		end

		const reader_buffer = reader.buffer
		reader.offset = offset + 12

		return Vector3.new(
			buffer.readf32(reader_buffer, offset),
			buffer.readf32(reader_buffer, offset + 4),
			buffer.readf32(reader_buffer, offset + 8)
		)
	end,

	min_size = 12,
	size = 12,
} :: Codec
