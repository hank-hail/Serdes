--!strict
--!native

const Core = require'./Core'

const resize = Core.resize

type Writer = Core.Writer
type Reader = Core.Reader
type Codec = Core.Codec<string>

const buffer_writestring = buffer.writestring
const buffer_readstring = buffer.readstring

return table.freeze{
	write = function(self: Codec, writer: Writer, value: string): ()
		if type(value) ~= "string" then
			error(`Serdes.string expected string, got {type(value)} instead`, 3)
		end

		const byte_length = #value

		local offset = writer.offset

		if byte_length < 0x80 then
			const needed_bytes = byte_length + 1

			if offset + needed_bytes > writer.capacity then
				resize(writer, needed_bytes)
			end

			const writer_buffer = writer.buffer

			buffer.writeu8(writer_buffer, offset, byte_length)

			if byte_length > 0 then
				buffer_writestring(writer_buffer, offset + 1, value)
			end

			writer.offset = offset + needed_bytes
			return
		end

		local prefix_size = 1
		local probe = byte_length // 128

		while probe > 0 do
			prefix_size += 1
			probe //= 128
		end

		const needed_bytes = prefix_size + byte_length

		if offset + needed_bytes > writer.capacity then
			resize(writer, needed_bytes)
		end

		const writer_buffer = writer.buffer
		local remaining = byte_length

		while remaining >= 0x80 do
			buffer.writeu8(writer_buffer, offset, remaining % 128 + 128)
			remaining //= 128
			offset += 1
		end

		buffer.writeu8(writer_buffer, offset, remaining)
		offset += 1

		buffer_writestring(writer_buffer, offset, value)

		writer.offset = offset + byte_length
	end,

	read = function(self: Codec, reader: Reader): string
		local offset = reader.offset
		const length = reader.length
		const reader_buffer = reader.buffer

		if offset + 1 > length then
			error(`Serdes read out of bounds. Needed 1 bytes at offset {offset}.`, 3)
		end

		const byte0 = buffer.readu8(reader_buffer, offset)
		offset += 1

		if byte0 < 0x80 then
			if byte0 == 0 then
				reader.offset = offset
				return ""
			end

			if offset + byte0 > length then
				error(`Serdes read out of bounds. Needed {byte0} bytes at offset {offset}.`, 3)
			end

			reader.offset = offset + byte0

			return buffer_readstring(reader_buffer, offset, byte0)
		end

		local byte_length = byte0 - 128
		local multiplier = 128

		for index = 2, 5 do
			if offset + 1 > length then
				error(`Serdes read out of bounds. Needed 1 bytes at offset {offset}.`, 3)
			end

			const byte = buffer.readu8(reader_buffer, offset)
			offset += 1

			if index == 5 and byte > 15 then
				error("Serdes.string length var_u32 overflowed u32 range.", 3)
			end

			if byte < 0x80 then
				byte_length += byte * multiplier

				if offset + byte_length > length then
					error(`Serdes read out of bounds. Needed {byte_length} bytes at offset {offset}.`, 3)
				end

				reader.offset = offset + byte_length

				return buffer_readstring(reader_buffer, offset, byte_length)
			end

			byte_length += (byte - 128) * multiplier
			multiplier *= 128
		end

		error("Serdes.string length var_u32 used too many bytes.", 3)
	end,

	min_size = 1,
} :: Codec
